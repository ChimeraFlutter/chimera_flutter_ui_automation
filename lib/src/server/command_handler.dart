import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/ui_state_capture.dart';
import '../core/function_registry.dart';
import '../core/behavior_recorder.dart';
import '../core/replay_engine.dart';
import '../core/screenshot_service.dart';
import '../models/recording_session.dart';
import '../models/screenshot_result.dart';
import '../exceptions/screenshot_exception.dart';
import 'protocol.dart';

/// Handles WebSocket commands
class CommandHandler {
  final BuildContext? context;
  final BehaviorRecorder recorder = BehaviorRecorder();
  final ReplayEngine replayEngine = ReplayEngine();

  CommandHandler({this.context});

  /// Process a WebSocket message
  Future<String> handleMessage(String message) async {
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      final request = WSRequest.fromJson(json);

      final response = await _handleCommand(request);
      return jsonEncode(response.toJson());
    } catch (e) {
      final response = WSResponse.error('Invalid message format: $e');
      return jsonEncode(response.toJson());
    }
  }

  Future<WSResponse> _handleCommand(WSRequest request) async {
    switch (request.command) {
      case 'getUI':
        return _handleGetUI(request.params);
      case 'tap':
        return _handleTap(request.params);
      case 'input':
        return _handleInput(request.params);
      case 'startRecord':
        return _handleStartRecord(request.params);
      case 'stopRecord':
        return _handleStopRecord();
      case 'replay':
        return _handleReplay(request.params);
      case 'screenshot':
        return await _handleScreenshot(request.params);
      default:
        return WSResponse.error('Unknown command: ${request.command}');
    }
  }

  WSResponse _handleGetUI(Map<String, dynamic>? params) {
    try {
      final snapshot = UIStateCapture.captureCurrentState(context);
      return WSResponse.success(data: snapshot.toJson());
    } catch (e) {
      return WSResponse.error('Failed to capture UI state: $e');
    }
  }

  WSResponse _handleTap(Map<String, dynamic>? params) {
    if (params == null || !params.containsKey('identifier')) {
      return WSResponse.error('Missing identifier parameter');
    }

    final identifier = params['identifier'] as String;
    final functionInfo = FunctionRegistry.get(identifier);

    if (functionInfo == null) {
      return WSResponse.error('Element not found: $identifier');
    }

    try {
      final callback = functionInfo.callback;
      if (callback is void Function()) {
        callback();
      } else {
        (callback as Function)();
      }
      return WSResponse.success(message: 'Tapped on $identifier');
    } catch (e) {
      return WSResponse.error('Failed to tap: $e');
    }
  }

  WSResponse _handleInput(Map<String, dynamic>? params) {
    if (params == null || !params.containsKey('identifier') || !params.containsKey('text')) {
      return WSResponse.error('Missing identifier or text parameter');
    }

    final identifier = params['identifier'] as String;
    final text = params['text'] as String;
    final functionInfo = FunctionRegistry.get('${identifier}_onChanged');

    if (functionInfo == null) {
      return WSResponse.error('Text field not found: $identifier');
    }

    try {
      final callback = functionInfo.callback;
      if (callback is void Function(String)) {
        callback(text);
      }
      return WSResponse.success(message: 'Input text to $identifier');
    } catch (e) {
      return WSResponse.error('Failed to input text: $e');
    }
  }

  WSResponse _handleStartRecord(Map<String, dynamic>? params) {
    final sessionId = params?['sessionId'] as String? ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    final captureUIState = params?['captureUIState'] as bool? ?? false;

    try {
      recorder.startRecording(
        sessionId: sessionId,
        captureUIState: captureUIState,
      );
      return WSResponse.success(
        data: {'sessionId': sessionId},
        message: 'Recording started',
      );
    } catch (e) {
      return WSResponse.error('Failed to start recording: $e');
    }
  }

  WSResponse _handleStopRecord() {
    try {
      final session = recorder.stopRecording();
      if (session == null) {
        return WSResponse.error('No active recording session');
      }
      return WSResponse.success(
        data: session.toJson(),
        message: 'Recording stopped',
      );
    } catch (e) {
      return WSResponse.error('Failed to stop recording: $e');
    }
  }

  Future<WSResponse> _handleReplay(Map<String, dynamic>? params) async {
    if (params == null || !params.containsKey('session')) {
      return WSResponse.error('Missing session parameter');
    }

    try {
      final sessionJson = params['session'] as Map<String, dynamic>;
      final session = RecordingSession.fromJson(sessionJson);
      final result = await replayEngine.replay(session);
      return WSResponse.success(data: result.toJson());
    } catch (e) {
      return WSResponse.error('Failed to replay: $e');
    }
  }

  Future<WSResponse> _handleScreenshot(Map<String, dynamic>? params) async {
    try {
      // Parse parameters with defaults
      final pixelRatio = (params?['pixelRatio'] as num?)?.toDouble() ?? 1.0;
      final includeMetadata = params?['includeMetadata'] as bool? ?? true;
      final maxRecentActions = params?['maxRecentActions'] as int? ?? 10;

      // Validate pixelRatio
      if (pixelRatio <= 0 || pixelRatio > 3.0) {
        return WSResponse.error('pixelRatio must be between 0 and 3.0');
      }

      // Capture screenshot
      final result = await ScreenshotService.instance.captureScreen(
        pixelRatio: pixelRatio,
        includeMetadata: includeMetadata,
        maxRecentActions: maxRecentActions,
      );

      // Return response with screenshot data
      return WSResponse.success(
        data: result.toJson(),
        message: 'Screenshot captured successfully',
      );
    } on ScreenshotException catch (e) {
      return WSResponse.error('Screenshot failed: ${e.message}');
    } catch (e) {
      return WSResponse.error('Screenshot failed: $e');
    }
  }
}
