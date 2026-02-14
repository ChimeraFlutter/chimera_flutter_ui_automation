import 'package:flutter/semantics.dart';
import '../models/user_action.dart';
import '../models/recording_session.dart';
import '../models/ui_snapshot.dart';
import 'function_registry.dart';
import 'ui_state_capture.dart';

/// Records user behavior for later replay
class BehaviorRecorder {
  static BehaviorRecorder? _instance;
  RecordingSession? _currentSession;
  final List<UserAction> _actions = [];

  BehaviorRecorder._();

  factory BehaviorRecorder() {
    _instance ??= BehaviorRecorder._();
    return _instance!;
  }

  /// Start recording a new session
  void startRecording({
    required String sessionId,
    bool captureUIState = false,
    Map<String, dynamic>? metadata,
  }) {
    if (_currentSession != null && _currentSession!.isActive) {
      throw StateError('A recording session is already active');
    }

    _actions.clear();
    _currentSession = RecordingSession(
      sessionId: sessionId,
      startTime: DateTime.now(),
      actions: _actions,
      metadata: metadata ?? {},
    );

    // Set up semantics listener
    _setupSemanticsListener(captureUIState);
  }

  /// Stop the current recording session
  RecordingSession? stopRecording() {
    if (_currentSession == null) {
      return null;
    }

    final session = RecordingSession(
      sessionId: _currentSession!.sessionId,
      startTime: _currentSession!.startTime,
      endTime: DateTime.now(),
      actions: List.from(_actions),
      metadata: _currentSession!.metadata,
    );

    _currentSession = null;
    _actions.clear();

    return session;
  }

  /// Check if recording is active
  bool get isRecording => _currentSession != null && _currentSession!.isActive;

  /// Get current session
  RecordingSession? get currentSession => _currentSession;

  void _setupSemanticsListener(bool captureUIState) {
    // Note: In a real implementation, we would set up a listener
    // for SemanticsAction events. However, Flutter doesn't provide
    // a direct way to listen to all semantics actions globally.
    // This would need to be integrated at the app level.
  }

  /// Manually record an action (called from TrackedWidgets)
  void recordAction({
    required String actionType,
    required String targetIdentifier,
    required String targetLabel,
    String? functionName,
    String? functionId,
    dynamic arguments,
    UISnapshot? uiStateBefore,
  }) {
    if (!isRecording) return;

    final action = UserAction(
      timestamp: DateTime.now(),
      actionType: actionType,
      targetIdentifier: targetIdentifier,
      targetLabel: targetLabel,
      functionName: functionName,
      functionId: functionId,
      arguments: arguments,
      uiStateBefore: uiStateBefore,
    );

    _actions.add(action);
  }

  /// Save session to JSON
  String saveToJson(RecordingSession session) {
    return session.toJson().toString();
  }

  /// Load session from JSON
  RecordingSession loadFromJson(Map<String, dynamic> json) {
    return RecordingSession.fromJson(json);
  }
}
