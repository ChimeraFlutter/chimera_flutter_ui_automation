import 'package:flutter/semantics.dart';
import '../models/recording_session.dart';
import '../models/user_action.dart';
import 'function_registry.dart';

/// Result of a replay operation
class ReplayResult {
  final bool success;
  final int totalActions;
  final int successfulActions;
  final List<String> errors;

  ReplayResult({
    required this.success,
    required this.totalActions,
    required this.successfulActions,
    required this.errors,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'totalActions': totalActions,
      'successfulActions': successfulActions,
      'errors': errors,
    };
  }
}

/// Engine for replaying recorded user actions
class ReplayEngine {
  /// Replay a recording session
  Future<ReplayResult> replay(RecordingSession session) async {
    final errors = <String>[];
    int successCount = 0;

    for (final action in session.actions) {
      try {
        final success = await _replayAction(action);
        if (success) {
          successCount++;
        } else {
          errors.add('Failed to replay action: ${action.actionType} on ${action.targetIdentifier}');
        }
      } catch (e) {
        errors.add('Error replaying action: $e');
      }

      // Add a small delay between actions to simulate real user behavior
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return ReplayResult(
      success: errors.isEmpty,
      totalActions: session.actions.length,
      successfulActions: successCount,
      errors: errors,
    );
  }

  Future<bool> _replayAction(UserAction action) async {
    // Try direct function call first (more reliable)
    if (action.functionId != null) {
      final success = await _replayViaDirectCall(action);
      if (success) return true;
    }

    // Fallback to semantics action
    return await _replayViaSemanticsAction(action);
  }

  /// Replay by directly calling the registered function
  Future<bool> _replayViaDirectCall(UserAction action) async {
    final functionInfo = FunctionRegistry.get(action.targetIdentifier);
    if (functionInfo == null) return false;

    try {
      final callback = functionInfo.callback;

      // Handle different callback types
      if (action.actionType == 'tap' && callback is Function) {
        if (callback is void Function()) {
          callback();
        } else {
          callback();
        }
        return true;
      } else if (action.actionType == 'setText' && callback is Function) {
        if (callback is void Function(String)) {
          callback(action.arguments as String);
        }
        return true;
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  /// Replay by triggering semantics action
  Future<bool> _replayViaSemanticsAction(UserAction action) async {
    // Note: This would require access to the SemanticsOwner
    // and finding the specific SemanticsNode by identifier.
    // This is a simplified implementation.

    // In a real implementation, we would:
    // 1. Get the SemanticsOwner
    // 2. Find the node with matching identifier
    // 3. Call performAction on that node

    return false;
  }
}
