import 'package:flutter/material.dart';

/// Observer to track current route
class AutomationNavigatorObserver extends NavigatorObserver {
  static String? _currentRoute = 'HomePage'; // 默认首页

  static String? get currentRoute => _currentRoute;

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _updateRoute(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _updateRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _updateRoute(newRoute);
    }
  }

  void _updateRoute(Route route) {
    if (route.settings.name != null) {
      _currentRoute = route.settings.name;
      print('[NavigatorObserver] Current route: $_currentRoute');
    } else {
      // Try to get route name from route type
      final routeType = route.runtimeType.toString();
      _currentRoute = routeType;
      print('[NavigatorObserver] Current route (from type): $_currentRoute');
    }
  }
}
