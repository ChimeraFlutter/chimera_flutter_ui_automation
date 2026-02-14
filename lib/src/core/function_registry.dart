import '../models/function_info.dart';

/// Global registry for tracking function callbacks
class FunctionRegistry {
  static final Map<String, FunctionInfo> _registry = {};

  /// Register a function
  static void register(String identifier, FunctionInfo info) {
    _registry[identifier] = info;
  }

  /// Get a function by identifier
  static FunctionInfo? get(String identifier) {
    return _registry[identifier];
  }

  /// Unregister a function
  static void unregister(String identifier) {
    _registry.remove(identifier);
  }

  /// Get all registered functions
  static List<FunctionInfo> getAll() {
    return _registry.values.toList();
  }

  /// Get all identifiers
  static List<String> getAllIdentifiers() {
    return _registry.keys.toList();
  }

  /// Check if an identifier is registered
  static bool contains(String identifier) {
    return _registry.containsKey(identifier);
  }

  /// Clear all registrations
  static void clear() {
    _registry.clear();
  }

  /// Get count of registered functions
  static int get count => _registry.length;
}
