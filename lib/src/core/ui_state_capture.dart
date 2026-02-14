import 'dart:ui' show SemanticsAction, SemanticsFlag;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/semantics.dart';
import '../models/ui_snapshot.dart';
import '../models/ui_element.dart';
import 'function_registry.dart';
import 'navigator_observer.dart';

/// Captures the current UI state from the Semantics tree
class UIStateCapture {
  /// Capture the current UI state
  static UISnapshot captureCurrentState(BuildContext? context) {
    final elements = <UIElement>[];
    String? currentPage;

    // Try to get current page from NavigatorObserver first
    currentPage = AutomationNavigatorObserver.currentRoute;

    // Convert "/" to "HomePage" for better readability
    if (currentPage == '/') {
      currentPage = 'HomePage';
    }

    // Fallback to context if available
    if (currentPage == null && context != null) {
      final route = ModalRoute.of(context);
      currentPage = route?.settings.name ?? context.widget.runtimeType.toString();
      if (currentPage == '/') {
        currentPage = 'HomePage';
      }
    }

    // Get the semantics owner
    final binding = WidgetsBinding.instance;

    // Force a frame to ensure semantics are up to date
    binding.scheduleFrame();

    final semanticsOwner = binding.pipelineOwner.semanticsOwner;

    print('[UIStateCapture] SemanticsOwner: ${semanticsOwner != null ? "available" : "null"}');

    if (semanticsOwner != null) {
      final rootNode = semanticsOwner.rootSemanticsNode;
      print('[UIStateCapture] Root node: ${rootNode != null ? "available" : "null"}');

      if (rootNode != null) {
        // Traverse the root node itself
        _traverseNode(rootNode, elements);

        // Also traverse its children
        rootNode.visitChildren((node) {
          _traverseNode(node, elements);
          return true;
        });
      } else {
        print('[UIStateCapture] WARNING: Root semantics node is null. Semantics tree may not be built yet.');
      }
    } else {
      print('[UIStateCapture] WARNING: SemanticsOwner is null. Make sure Semantics are enabled.');
    }

    print('[UIStateCapture] Captured ${elements.length} elements');

    // Try to infer page name from elements if not found
    if (currentPage == null) {
      // Look for page title indicators in labels
      for (final element in elements) {
        final label = element.label.toLowerCase();
        if (label.contains('页面') || label.contains('page')) {
          currentPage = element.label;
          print('[UIStateCapture] Inferred page from label: $currentPage');
          break;
        }
      }
    }

    // If still no page name, use a generic one
    if (currentPage == null && elements.isNotEmpty) {
      currentPage = 'CurrentPage';
    }

    print('[UIStateCapture] Current page: $currentPage');

    return UISnapshot(
      timestamp: DateTime.now(),
      currentPage: currentPage,
      elements: elements,
    );
  }

  static void _traverseNode(SemanticsNode node, List<UIElement> elements) {
    // Get semantics data from the node
    final data = node.getSemanticsData();

    // Extract information from the data
    final identifier = data.identifier;
    final label = data.label;
    final value = data.value;
    final rect = data.rect;

    // Get available actions using bit operations
    final actions = <String>[];
    if ((data.actions & SemanticsAction.tap.index) != 0) actions.add('tap');
    if ((data.actions & SemanticsAction.longPress.index) != 0) actions.add('longPress');
    if ((data.actions & SemanticsAction.scrollLeft.index) != 0) actions.add('scrollLeft');
    if ((data.actions & SemanticsAction.scrollRight.index) != 0) actions.add('scrollRight');
    if ((data.actions & SemanticsAction.scrollUp.index) != 0) actions.add('scrollUp');
    if ((data.actions & SemanticsAction.scrollDown.index) != 0) actions.add('scrollDown');
    if ((data.actions & SemanticsAction.increase.index) != 0) actions.add('increase');
    if ((data.actions & SemanticsAction.decrease.index) != 0) actions.add('decrease');
    if ((data.actions & SemanticsAction.setText.index) != 0) actions.add('setText');

    // Determine element type from flags
    String type = 'unknown';
    final flags = data.flagsCollection;
    if (flags.isButton) {
      type = 'button';
    } else if (flags.isTextField) {
      type = 'textField';
    } else if (flags.isSlider) {
      type = 'slider';
    } else if (flags.isLink) {
      type = 'link';
    } else if (flags.isImage) {
      type = 'image';
    }

    // Only add elements that have an identifier or label
    if (identifier.isNotEmpty || label.isNotEmpty) {
      // Try to find associated function info
      final functionInfo = FunctionRegistry.get(identifier);

      final element = UIElement(
        identifier: identifier,
        label: label,
        value: value.isNotEmpty ? value : null,
        type: type,
        rect: rect,
        actions: actions,
        functionInfo: functionInfo,
        visible: !flags.isHidden,
      );

      elements.add(element);
    }

    // Recursively traverse children
    node.visitChildren((child) {
      _traverseNode(child, elements);
      return true;
    });
  }
}
