import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

/// VM Service integration for Hot Reload and Hot Restart
class VMServiceIntegration {
  static VmService? _vmService;
  static bool _initialized = false;

  /// Initialize VM Service connection
  static Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    try {
      // Get VM Service info
      final serviceInfo = await developer.Service.getInfo();
      final wsUri = serviceInfo.serverWebSocketUri;

      if (wsUri == null) {
        debugPrint('[VMService] VM Service not available (probably running in release mode)');
        return false;
      }

      debugPrint('[VMService] Connecting to VM Service: $wsUri');

      // Connect to VM Service
      _vmService = await vmServiceConnectUri(wsUri.toString());
      _initialized = true;

      debugPrint('[VMService] Successfully connected to VM Service');
      return true;
    } catch (e) {
      debugPrint('[VMService] Failed to initialize: $e');
      return false;
    }
  }

  /// Check if VM Service is available
  static bool get isAvailable => _initialized && _vmService != null;

  /// Perform Hot Reload (r)
  /// Reloads the source code without losing app state
  static Future<bool> hotReload({Duration compilationDelay = const Duration(seconds: 2)}) async {
    if (!isAvailable) {
      debugPrint('[VMService] VM Service not available');
      return false;
    }

    try {
      debugPrint('[VMService] Performing Hot Reload...');

      // Wait for Flutter tools to detect file changes and recompile
      debugPrint('[VMService] Waiting ${compilationDelay.inSeconds}s for compilation...');
      await Future.delayed(compilationDelay);

      // Get the main isolate
      final VM vmInfo = await _vmService!.getVM();
      if (vmInfo.isolates == null || vmInfo.isolates!.isEmpty) {
        debugPrint('[VMService] No isolates found');
        return false;
      }

      final isolateRef = vmInfo.isolates!.first;
      final isolateId = isolateRef.id!;

      // Try to call the reloadSources service registered by Flutter tools
      try {
        final response = await _vmService!.callMethod(
          'reloadSources',
          isolateId: isolateId,
          args: {
            'isolateId': isolateId,
            'force': false,
            'pause': false,
          },
        );
        debugPrint('[VMService] Hot Reload via service successful: ${response.json}');
        return true;
      } catch (e) {
        debugPrint('[VMService] Hot Reload via service failed: $e');

        // Fallback: try direct VM Service reloadSources
        final isolate = await _vmService!.getIsolate(isolateId);
        final rootLibUri = isolate.rootLib?.uri;

        final result = await _vmService!.reloadSources(
          isolateId,
          force: false,
          pause: false,
          rootLibUri: rootLibUri,
        );

        if (result.success == true) {
          debugPrint('[VMService] Hot Reload via direct call successful');
          return true;
        } else {
          debugPrint('[VMService] Hot Reload failed: ${result.toString()}');
          return false;
        }
      }
    } catch (e) {
      debugPrint('[VMService] Hot Reload error: $e');
      return false;
    }
  }

  /// Perform Hot Restart (R)
  /// Restarts the app completely, losing all state
  static Future<bool> hotRestart() async {
    if (!isAvailable) {
      debugPrint('[VMService] VM Service not available');
      return false;
    }

    try {
      debugPrint('[VMService] Performing Hot Restart...');

      // Try to call the hotRestart service if it's registered
      // This is typically registered by Flutter tools
      final response = await _vmService!.callServiceExtension(
        'ext.flutter.hotRestart',
        args: {'pause': false},
      );

      debugPrint('[VMService] Hot Restart response: ${response.json}');
      return true;
    } catch (e) {
      debugPrint('[VMService] Hot Restart via extension failed: $e');

      // Fallback: try to reload all isolates
      try {
        final VM vmInfo = await _vmService!.getVM();
        if (vmInfo.isolates == null || vmInfo.isolates!.isEmpty) {
          debugPrint('[VMService] No isolates found');
          return false;
        }

        for (final isolateRef in vmInfo.isolates!) {
          final isolateId = isolateRef.id!;
          await _vmService!.reloadSources(
            isolateId,
            force: true,
            pause: false,
          );
        }

        debugPrint('[VMService] Hot Restart via reloadSources successful');
        return true;
      } catch (e2) {
        debugPrint('[VMService] Hot Restart fallback failed: $e2');
        return false;
      }
    }
  }

  /// Get VM Service info
  static Future<Map<String, dynamic>> getVMInfo() async {
    if (!isAvailable) {
      return {
        'available': false,
        'message': 'VM Service not available',
      };
    }

    try {
      final vmInfo = await _vmService!.getVM();
      return {
        'available': true,
        'version': vmInfo.version,
        'isolates': vmInfo.isolates?.length ?? 0,
        'targetCPU': vmInfo.targetCPU,
        'hostCPU': vmInfo.hostCPU,
        'startTime': vmInfo.startTime,
      };
    } catch (e) {
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  /// Disconnect from VM Service
  static Future<void> disconnect() async {
    if (_vmService != null) {
      await _vmService!.dispose();
      _vmService = null;
      _initialized = false;
      debugPrint('[VMService] Disconnected');
    }
  }
}
