import 'package:flutter/material.dart';
import '../core/function_registry.dart';
import '../models/function_info.dart';

/// A button widget that tracks its callback function
class TrackedButton extends StatefulWidget {
  /// Unique identifier for this button
  final String identifier;

  /// Optional function name for logging
  final String? functionName;

  /// The actual callback
  final VoidCallback? onPressed;

  /// Button child widget
  final Widget child;

  /// Additional metadata
  final Map<String, dynamic>? metadata;

  /// Button style
  final ButtonStyle? style;

  const TrackedButton({
    super.key,
    required this.identifier,
    this.functionName,
    required this.onPressed,
    required this.child,
    this.metadata,
    this.style,
  });

  @override
  State<TrackedButton> createState() => _TrackedButtonState();
}

class _TrackedButtonState extends State<TrackedButton> {
  @override
  void initState() {
    super.initState();
    _registerFunction();
  }

  @override
  void dispose() {
    FunctionRegistry.unregister(widget.identifier);
    super.dispose();
  }

  void _registerFunction() {
    if (widget.onPressed != null) {
      final info = FunctionInfo(
        identifier: widget.identifier,
        functionName: widget.functionName ?? 'onPressed',
        callback: widget.onPressed!,
        widgetType: 'button',
        metadata: widget.metadata ?? {},
      );
      FunctionRegistry.register(widget.identifier, info);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract text from child if possible
    String label = widget.identifier;
    if (widget.child is Text) {
      label = (widget.child as Text).data ?? widget.identifier;
    }

    return Semantics(
      identifier: widget.identifier,
      label: label,
      button: true,
      enabled: widget.onPressed != null,
      onTap: widget.onPressed,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: widget.style,
        child: widget.child,
      ),
    );
  }
}
