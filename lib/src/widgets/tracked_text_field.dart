import 'package:flutter/material.dart';
import '../core/function_registry.dart';
import '../models/function_info.dart';

/// A text field widget that tracks its callback functions
class TrackedTextField extends StatefulWidget {
  /// Unique identifier for this text field
  final String identifier;

  /// Optional function name for logging
  final String? functionName;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Callback when submitted
  final ValueChanged<String>? onSubmitted;

  /// Text controller
  final TextEditingController? controller;

  /// Decoration
  final InputDecoration? decoration;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  const TrackedTextField({
    super.key,
    required this.identifier,
    this.functionName,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.decoration,
    this.metadata,
  });

  @override
  State<TrackedTextField> createState() => _TrackedTextFieldState();
}

class _TrackedTextFieldState extends State<TrackedTextField> {
  @override
  void initState() {
    super.initState();
    _registerFunctions();
  }

  @override
  void dispose() {
    FunctionRegistry.unregister('${widget.identifier}_onChanged');
    FunctionRegistry.unregister('${widget.identifier}_onSubmitted');
    super.dispose();
  }

  void _registerFunctions() {
    if (widget.onChanged != null) {
      final info = FunctionInfo(
        identifier: '${widget.identifier}_onChanged',
        functionName: widget.functionName ?? 'onChanged',
        callback: widget.onChanged!,
        widgetType: 'textField',
        metadata: widget.metadata ?? {},
      );
      FunctionRegistry.register('${widget.identifier}_onChanged', info);
    }

    if (widget.onSubmitted != null) {
      final info = FunctionInfo(
        identifier: '${widget.identifier}_onSubmitted',
        functionName: widget.functionName ?? 'onSubmitted',
        callback: widget.onSubmitted!,
        widgetType: 'textField',
        metadata: widget.metadata ?? {},
      );
      FunctionRegistry.register('${widget.identifier}_onSubmitted', info);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: widget.identifier,
      label: widget.decoration?.labelText ?? widget.identifier,
      textField: true,
      child: TextField(
        controller: widget.controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: widget.decoration,
      ),
    );
  }
}
