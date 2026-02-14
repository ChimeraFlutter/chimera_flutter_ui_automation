import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../core/function_registry.dart';
import '../models/function_info.dart';

/// A gesture detector that tracks its callback functions
class TrackedGestureDetector extends StatefulWidget {
  /// Unique identifier
  final String identifier;

  /// Optional function name
  final String? functionName;

  /// Tap callback
  final GestureTapCallback? onTap;

  /// Long press callback
  final GestureLongPressCallback? onLongPress;

  /// Double tap callback
  final GestureTapCallback? onDoubleTap;

  /// Child widget
  final Widget child;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const TrackedGestureDetector({
    super.key,
    required this.identifier,
    this.functionName,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    required this.child,
    this.metadata,
  });

  @override
  State<TrackedGestureDetector> createState() =>
      _TrackedGestureDetectorState();
}

class _TrackedGestureDetectorState extends State<TrackedGestureDetector> {
  @override
  void initState() {
    super.initState();
    _registerFunctions();
  }

  @override
  void dispose() {
    FunctionRegistry.unregister('${widget.identifier}_onTap');
    FunctionRegistry.unregister('${widget.identifier}_onLongPress');
    FunctionRegistry.unregister('${widget.identifier}_onDoubleTap');
    super.dispose();
  }

  void _registerFunctions() {
    if (widget.onTap != null) {
      final info = FunctionInfo(
        identifier: '${widget.identifier}_onTap',
        functionName: widget.functionName ?? 'onTap',
        callback: widget.onTap!,
        widgetType: 'gestureDetector',
        metadata: widget.metadata ?? {},
      );
      FunctionRegistry.register('${widget.identifier}_onTap', info);
    }

    if (widget.onLongPress != null) {
      final info = FunctionInfo(
        identifier: '${widget.identifier}_onLongPress',
        functionName: widget.functionName ?? 'onLongPress',
        callback: widget.onLongPress!,
        widgetType: 'gestureDetector',
        metadata: widget.metadata ?? {},
      );
      FunctionRegistry.register('${widget.identifier}_onLongPress', info);
    }

    if (widget.onDoubleTap != null) {
      final info = FunctionInfo(
        identifier: '${widget.identifier}_onDoubleTap',
        functionName: widget.functionName ?? 'onDoubleTap',
        callback: widget.onDoubleTap!,
        widgetType: 'gestureDetector',
        metadata: widget.metadata ?? {},
      );
      FunctionRegistry.register('${widget.identifier}_onDoubleTap', info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: widget.identifier,
      label: widget.identifier,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onDoubleTap: widget.onDoubleTap,
        child: widget.child,
      ),
    );
  }
}
