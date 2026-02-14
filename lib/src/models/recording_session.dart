import 'user_action.dart';

/// A recording session containing a sequence of user actions
class RecordingSession {
  /// Unique session ID
  final String sessionId;

  /// When recording started
  final DateTime startTime;

  /// When recording ended
  final DateTime? endTime;

  /// All recorded actions
  final List<UserAction> actions;

  /// Session metadata
  final Map<String, dynamic> metadata;

  RecordingSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.actions,
    this.metadata = const {},
  });

  /// Duration of the recording
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Whether recording is still active
  bool get isActive => endTime == null;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'actions': actions.map((a) => a.toJson()).toList(),
      'metadata': metadata,
    };
  }

  factory RecordingSession.fromJson(Map<String, dynamic> json) {
    return RecordingSession(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      actions: (json['actions'] as List)
          .map((a) => UserAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
