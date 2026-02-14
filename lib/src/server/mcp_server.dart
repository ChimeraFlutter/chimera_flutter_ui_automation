import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ui_snapshot.dart';
import '../models/ui_element.dart';
import '../core/function_registry.dart';
import '../core/behavior_recorder.dart';
import '../core/replay_engine.dart';
import '../core/ui_state_capture.dart';
import '../core/vm_service_integration.dart';

/// MCP (Model Context Protocol) HTTP Server
/// Implements MCP 2025-06-18 specification for Claude Code integration
class MCPServer {
  final int port;
  final String? token;
  final BehaviorRecorder? behaviorRecorder;
  final ReplayEngine? replayEngine;

  HttpServer? _server;
  bool _isRunning = false;
  int _requestId = 0;

  MCPServer({
    required this.port,
    this.token,
    this.behaviorRecorder,
    this.replayEngine,
  });

  bool get isRunning => _isRunning;

  /// Start the MCP HTTP server
  Future<void> start() async {
    if (_isRunning) {
      debugPrint('[MCP] Server already running on port $port');
      return;
    }

    try {
      // Initialize VM Service for Hot Reload/Restart
      await VMServiceIntegration.initialize();

      // Only bind to localhost for security
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _isRunning = true;

      debugPrint('[MCP] Server started on http://127.0.0.1:$port/mcp');
      debugPrint('[MCP] Token authentication: DISABLED');

      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('[MCP] Failed to start server: $e');
      rethrow;
    }
  }

  /// Stop the MCP HTTP server
  Future<void> stop() async {
    if (!_isRunning) return;

    await _server?.close();
    _server = null;
    _isRunning = false;
    debugPrint('[MCP] Server stopped');
  }

  /// Handle incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    // Set CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', 'http://localhost:*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type, X-MCP-Token');

    // Handle OPTIONS preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    // Only accept POST requests to /mcp endpoint
    if (request.method != 'POST' || request.uri.path != '/mcp') {
      _sendError(request.response, -32600, 'Invalid Request', 'Only POST to /mcp is supported');
      return;
    }

    // Token authentication disabled for easier access

    // Validate Origin header (prevent DNS rebinding)
    final origin = request.headers.value('Origin');
    final host = request.headers.value('Host');
    if (origin != null && !_isValidOrigin(origin)) {
      _sendError(request.response, -32002, 'Forbidden', 'Invalid origin');
      return;
    }
    if (host != null && !host.startsWith('127.0.0.1:') && !host.startsWith('localhost:')) {
      _sendError(request.response, -32002, 'Forbidden', 'Invalid host');
      return;
    }

    try {
      // Read request body
      final body = await utf8.decoder.bind(request).join();
      final jsonRequest = jsonDecode(body) as Map<String, dynamic>;

      // Validate JSON-RPC 2.0 format
      if (jsonRequest['jsonrpc'] != '2.0') {
        _sendError(request.response, -32600, 'Invalid Request', 'Must be JSON-RPC 2.0');
        return;
      }

      final method = jsonRequest['method'] as String?;
      final id = jsonRequest['id'];

      if (method == null) {
        _sendError(request.response, -32600, 'Invalid Request', 'Missing method');
        return;
      }

      // Handle MCP methods
      final response = await _handleMCPMethod(method, jsonRequest['params'] as Map<String, dynamic>?, id);
      _sendResponse(request.response, response);
    } catch (e) {
      debugPrint('[MCP] Error handling request: $e');
      _sendError(request.response, -32603, 'Internal error', e.toString());
    }
  }

  /// Validate origin for CORS
  bool _isValidOrigin(String origin) {
    // Only allow localhost origins
    return origin.startsWith('http://localhost:') ||
        origin.startsWith('http://127.0.0.1:') ||
        origin == 'http://localhost' ||
        origin == 'http://127.0.0.1';
  }

  /// Handle MCP protocol methods
  Future<Map<String, dynamic>> _handleMCPMethod(
    String method,
    Map<String, dynamic>? params,
    dynamic id,
  ) async {
    switch (method) {
      case 'initialize':
        return _handleInitialize(params, id);

      case 'tools/list':
        return _handleToolsList(id);

      case 'tools/call':
        return await _handleToolsCall(params, id);

      case 'ping':
        return _handlePing(id);

      default:
        return {
          'jsonrpc': '2.0',
          'id': id,
          'error': {
            'code': -32601,
            'message': 'Method not found',
            'data': 'Unknown method: $method',
          },
        };
    }
  }

  /// Handle initialize method
  Map<String, dynamic> _handleInitialize(Map<String, dynamic>? params, dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'protocolVersion': '2025-06-18',
        'serverInfo': {
          'name': 'chimera_flutter_ui_automation',
          'version': '0.0.1',
        },
        'capabilities': {
          'tools': {},
        },
      },
    };
  }

  /// Handle tools/list method
  Map<String, dynamic> _handleToolsList(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {
        'tools': [
          {
            'name': 'ui.snapshot',
            'description': '获取当前 Flutter 界面的完整描述（纯文本格式）',
            'inputSchema': {
              'type': 'object',
              'properties': {},
            },
          },
          {
            'name': 'ui.tap',
            'description': '点击指定的 UI 元素',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'elementId': {
                  'type': 'string',
                  'description': '元素 ID 或 identifier',
                },
              },
              'required': ['elementId'],
            },
          },
          {
            'name': 'ui.tap_by_label',
            'description': '通过标签文本查找并点击元素（支持模糊匹配）',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'label': {
                  'type': 'string',
                  'description': '元素标签文本',
                },
              },
              'required': ['label'],
            },
          },
          {
            'name': 'ui.input_text',
            'description': '在文本输入框中输入文本',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'elementId': {
                  'type': 'string',
                  'description': '文本框元素 ID',
                },
                'text': {
                  'type': 'string',
                  'description': '要输入的文本',
                },
              },
              'required': ['elementId', 'text'],
            },
          },
          {
            'name': 'ui.scroll',
            'description': '滚动界面',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'direction': {
                  'type': 'string',
                  'enum': ['up', 'down', 'left', 'right'],
                  'description': '滚动方向',
                },
                'amount': {
                  'type': 'number',
                  'description': '滚动距离（像素），默认 100',
                },
              },
              'required': ['direction'],
            },
          },
          {
            'name': 'ui.get_screen',
            'description': '获取当前屏幕/页面的名称和路由信息',
            'inputSchema': {
              'type': 'object',
              'properties': {},
            },
          },
          {
            'name': 'ui.start_recording',
            'description': '开始录制用户操作',
            'inputSchema': {
              'type': 'object',
              'properties': {
                'sessionId': {
                  'type': 'string',
                  'description': '录制会话 ID',
                },
              },
            },
          },
          {
            'name': 'ui.stop_recording',
            'description': '停止录制并返回录制的操作序列',
            'inputSchema': {
              'type': 'object',
              'properties': {},
            },
          },
          {
            'name': 'dev.vm_info',
            'description': '获取 Dart VM 信息',
            'inputSchema': {
              'type': 'object',
              'properties': {},
            },
          },
        ],
      },
    };
  }

  /// Handle tools/call method
  Future<Map<String, dynamic>> _handleToolsCall(Map<String, dynamic>? params, dynamic id) async {
    if (params == null || params['name'] == null) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {
          'code': -32602,
          'message': 'Invalid params',
          'data': 'Missing tool name',
        },
      };
    }

    final toolName = params['name'] as String;
    final arguments = params['arguments'] as Map<String, dynamic>? ?? {};

    try {
      final result = await _executeTool(toolName, arguments);
      return {
        'jsonrpc': '2.0',
        'id': id,
        'result': result,
      };
    } catch (e) {
      return {
        'jsonrpc': '2.0',
        'id': id,
        'error': {
          'code': -32000,
          'message': 'Tool execution failed',
          'data': e.toString(),
        },
      };
    }
  }

  /// Handle ping method
  Map<String, dynamic> _handlePing(dynamic id) {
    return {
      'jsonrpc': '2.0',
      'id': id,
      'result': {'status': 'ok'},
    };
  }

  /// Execute a tool
  Future<Map<String, dynamic>> _executeTool(String toolName, Map<String, dynamic> arguments) async {
    switch (toolName) {
      case 'ui.snapshot':
        return await _toolSnapshot();

      case 'ui.tap':
        return await _toolTap(arguments);

      case 'ui.tap_by_label':
        return await _toolTapByLabel(arguments);

      case 'ui.input_text':
        return await _toolInputText(arguments);

      case 'ui.scroll':
        return await _toolScroll(arguments);

      case 'ui.get_screen':
        return _toolGetScreen();

      case 'ui.start_recording':
        return _toolStartRecording(arguments);

      case 'ui.stop_recording':
        return _toolStopRecording();

      case 'dev.vm_info':
        return await _toolVMInfo();

      default:
        throw Exception('Unknown tool: $toolName');
    }
  }

  /// Tool: ui.snapshot
  Future<Map<String, dynamic>> _toolSnapshot() async {
    final snapshot = UIStateCapture.captureCurrentState(null);
    final text = _formatSnapshotAsText(snapshot);

    return {
      'content': [
        {
          'type': 'text',
          'text': text,
        },
      ],
    };
  }

  /// Tool: ui.tap
  Future<Map<String, dynamic>> _toolTap(Map<String, dynamic> arguments) async {
    final elementId = arguments['elementId'] as String?;
    if (elementId == null) {
      throw Exception('Missing elementId parameter');
    }

    // Try to find and execute the function
    final functionInfo = FunctionRegistry.get(elementId);
    if (functionInfo == null) {
      throw Exception('Element not found: $elementId');
    }

    try {
      functionInfo.callback();
      return {
        'content': [
          {
            'type': 'text',
            'text': '成功点击元素: $elementId',
          },
        ],
      };
    } catch (e) {
      throw Exception('Failed to execute tap: $e');
    }
  }

  /// Tool: ui.tap_by_label
  Future<Map<String, dynamic>> _toolTapByLabel(Map<String, dynamic> arguments) async {
    final label = arguments['label'] as String?;
    if (label == null) {
      throw Exception('Missing label parameter');
    }

    // Get current UI state
    final snapshot = UIStateCapture.captureCurrentState(null);

    // Find element by label (fuzzy match)
    UIElement? targetElement;
    for (final element in snapshot.elements) {
      if (element.label.contains(label)) {
        targetElement = element;
        break;
      }
    }

    if (targetElement == null) {
      throw Exception('Element with label "$label" not found');
    }

    // Execute the function
    final functionInfo = FunctionRegistry.get(targetElement.identifier);
    if (functionInfo == null) {
      throw Exception('Function not found for element: ${targetElement.identifier}');
    }

    try {
      functionInfo.callback();
      return {
        'content': [
          {
            'type': 'text',
            'text': '成功点击元素: ${targetElement.label} (${targetElement.identifier})',
          },
        ],
      };
    } catch (e) {
      throw Exception('Failed to execute tap: $e');
    }
  }

  /// Tool: ui.input_text
  Future<Map<String, dynamic>> _toolInputText(Map<String, dynamic> arguments) async {
    final elementId = arguments['elementId'] as String?;
    final text = arguments['text'] as String?;

    if (elementId == null || text == null) {
      throw Exception('Missing elementId or text parameter');
    }

    // Execute the function with text parameter
    final functionInfo = FunctionRegistry.get(elementId);
    if (functionInfo == null) {
      throw Exception('Element not found: $elementId');
    }

    try {
      // Call the callback with the text parameter
      functionInfo.callback(text);
      return {
        'content': [
          {
            'type': 'text',
            'text': '成功输入文本到元素: $elementId',
          },
        ],
      };
    } catch (e) {
      throw Exception('Failed to input text: $e');
    }
  }

  /// Tool: ui.scroll
  Future<Map<String, dynamic>> _toolScroll(Map<String, dynamic> arguments) async {
    final direction = arguments['direction'] as String?;
    final amount = (arguments['amount'] as num?)?.toDouble() ?? 100.0;

    if (direction == null) {
      throw Exception('Missing direction parameter');
    }

    // TODO: Implement scroll functionality
    // This would require integration with Flutter's scrolling mechanisms

    return {
      'content': [
        {
          'type': 'text',
          'text': '滚动功能待实现: $direction, $amount px',
        },
      ],
    };
  }

  /// Tool: ui.get_screen
  Map<String, dynamic> _toolGetScreen() {
    final snapshot = UIStateCapture.captureCurrentState(null);
    final currentPage = snapshot.currentPage ?? 'Unknown';

    return {
      'content': [
        {
          'type': 'text',
          'text': '当前页面: $currentPage',
        },
      ],
    };
  }

  /// Tool: ui.start_recording
  Map<String, dynamic> _toolStartRecording(Map<String, dynamic> arguments) {
    if (behaviorRecorder == null) {
      throw Exception('Behavior recorder not enabled');
    }

    final sessionId = arguments['sessionId'] as String? ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    behaviorRecorder!.startRecording(sessionId: sessionId);

    return {
      'content': [
        {
          'type': 'text',
          'text': '开始录制会话: $sessionId',
        },
      ],
    };
  }

  /// Tool: ui.stop_recording
  Map<String, dynamic> _toolStopRecording() {
    if (behaviorRecorder == null) {
      throw Exception('Behavior recorder not enabled');
    }

    final session = behaviorRecorder!.stopRecording();

    if (session == null) {
      throw Exception('No active recording session');
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': '停止录制会话: ${session.sessionId}, 共 ${session.actions.length} 个操作',
        },
      ],
    };
  }

  /// Tool: dev.vm_info
  Future<Map<String, dynamic>> _toolVMInfo() async {
    final info = await VMServiceIntegration.getVMInfo();

    final buffer = StringBuffer();
    buffer.writeln('Dart VM 信息:');
    buffer.writeln('---');

    if (info['available'] == true) {
      buffer.writeln('状态: 可用');
      buffer.writeln('版本: ${info['version']}');
      buffer.writeln('Isolates: ${info['isolates']}');
      buffer.writeln('目标 CPU: ${info['targetCPU']}');
      buffer.writeln('主机 CPU: ${info['hostCPU']}');
      buffer.writeln('启动时间: ${info['startTime']}');
    } else {
      buffer.writeln('状态: 不可用');
      if (info['message'] != null) {
        buffer.writeln('原因: ${info['message']}');
      }
      if (info['error'] != null) {
        buffer.writeln('错误: ${info['error']}');
      }
    }

    return {
      'content': [
        {
          'type': 'text',
          'text': buffer.toString(),
        },
      ],
    };
  }

  /// Format UI snapshot as plain text
  String _formatSnapshotAsText(UISnapshot snapshot) {
    final buffer = StringBuffer();

    buffer.writeln('Screen: ${snapshot.currentPage}');
    buffer.writeln('Timestamp: ${snapshot.timestamp}');
    buffer.writeln('---');

    int index = 1;
    for (final element in snapshot.elements) {
      if (!element.visible) continue;

      final type = element.type;
      final label = element.label ?? element.identifier;
      final actions = element.actions.join(', ');

      buffer.write('[$index] $type "$label"');

      if (actions.isNotEmpty) {
        buffer.write(' - $actions');
      }

      if (element.functionInfo != null) {
        buffer.write(' (${element.functionInfo!.functionName})');
      }

      buffer.writeln();
      index++;
    }

    buffer.writeln('---');
    buffer.writeln('Total: ${snapshot.elements.length} elements, ${snapshot.elements.where((e) => e.actions.isNotEmpty).length} interactive');

    return buffer.toString();
  }

  /// Send JSON-RPC response
  void _sendResponse(HttpResponse response, Map<String, dynamic> data) {
    response.headers.contentType = ContentType.json;
    response.statusCode = 200;
    response.write(jsonEncode(data));
    response.close();
  }

  /// Send JSON-RPC error
  void _sendError(HttpResponse response, int code, String message, String? data) {
    response.headers.contentType = ContentType.json;
    response.statusCode = 200; // JSON-RPC errors still return 200
    response.write(jsonEncode({
      'jsonrpc': '2.0',
      'id': null,
      'error': {
        'code': code,
        'message': message,
        if (data != null) 'data': data,
      },
    }));
    response.close();
  }
}
