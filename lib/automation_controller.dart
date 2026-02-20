import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'src/server/websocket_server.dart';
import 'src/server/mcp_server.dart';
import 'src/core/function_registry.dart';
import 'src/core/behavior_recorder.dart';
import 'src/core/replay_engine.dart';
import 'src/core/ui_state_capture.dart';
import 'src/core/screenshot_service.dart';
import 'src/models/ui_snapshot.dart';

/// Main controller for the automation library
class AutomationController {
  static WebSocketServer? _wsServer;
  static MCPServer? _mcpServer;
  static bool _initialized = false;

  /// GlobalKey for screenshot capture
  static final GlobalKey screenshotKey = GlobalKey();

  /// Initialize the automation library
  static Future<void> initialize({
    int port = 59322,
    int? mcpPort,
    String? mcpToken,
    bool enableRecording = true,
    bool enableMCP = true,
    bool enableScreenshot = true,
    int screenshotRateLimitMs = 1000,
    BuildContext? context,
  }) async {
    if (_initialized) {
      print('AutomationController already initialized');
      return;
    }

    // Ensure semantics are enabled
    print('[AutomationController] Enabling semantics...');
    final semanticsHandle = WidgetsBinding.instance.ensureSemantics();

    // Force a frame to build the semantics tree
    WidgetsBinding.instance.scheduleFrame();

    // Wait for the semantics tree to be built
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if semantics are actually enabled
    final semanticsOwner = WidgetsBinding.instance.pipelineOwner.semanticsOwner;
    print('[AutomationController] SemanticsOwner after initialization: ${semanticsOwner != null ? "available" : "null"}');
    if (semanticsOwner != null) {
      print('[AutomationController] Root node: ${semanticsOwner.rootSemanticsNode != null ? "available" : "null"}');
    }

    // Start WebSocket server
    _wsServer = WebSocketServer(port: port, context: context);
    await _wsServer!.start();

    // Start MCP server if enabled
    if (enableMCP) {
      final actualMcpPort = mcpPort ?? 59323;

      final behaviorRecorder = enableRecording ? BehaviorRecorder() : null;
      final replayEngine = ReplayEngine();

      _mcpServer = MCPServer(
        port: actualMcpPort,
        token: null,  // Token disabled
        behaviorRecorder: behaviorRecorder,
        replayEngine: replayEngine,
      );

      await _mcpServer!.start();
      print('[AutomationController] MCP Server started on port $actualMcpPort');
      print('[AutomationController] Token authentication: DISABLED');
      print('[AutomationController] Connect with: claude mcp add --transport http chimera_flutter_ui http://127.0.0.1:$actualMcpPort/mcp');
    }

    // Initialize screenshot service
    if (enableScreenshot) {
      ScreenshotService.instance.setEnabled(true);
      ScreenshotService.instance.setRateLimit(screenshotRateLimitMs);
      ScreenshotService.instance.setScreenshotKey(screenshotKey);
      print('[AutomationController] Screenshot capture enabled (rate limit: ${screenshotRateLimitMs}ms)');
    } else {
      ScreenshotService.instance.setEnabled(false);
      print('[AutomationController] Screenshot capture disabled');
    }

    _initialized = true;
    print('AutomationController initialized on port $port');
  }

  /// Generate a random token for MCP authentication
  static String _generateToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'chimera_$timestamp';
  }

  /// Shutdown the automation library
  static Future<void> shutdown() async {
    if (!_initialized) {
      return;
    }

    await _wsServer?.stop();
    _wsServer = null;

    await _mcpServer?.stop();
    _mcpServer = null;

    FunctionRegistry.clear();
    _initialized = false;
    print('AutomationController shutdown');
  }

  /// Check if initialized
  static bool get isInitialized => _initialized;

  /// Get the WebSocket server
  static WebSocketServer? get server => _wsServer;

  /// Get the MCP server
  static MCPServer? get mcpServer => _mcpServer;

  /// Get the behavior recorder
  static BehaviorRecorder get recorder => BehaviorRecorder();

  /// Get the replay engine
  static ReplayEngine get replayEngine => ReplayEngine();

  /// Capture current UI state
  static UISnapshot captureUI(BuildContext? context) {
    return UIStateCapture.captureCurrentState(context);
  }
}
