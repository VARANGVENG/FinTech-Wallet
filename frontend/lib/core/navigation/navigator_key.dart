import 'package:flutter/material.dart';

/// Lets code outside the widget tree (an FCM notification-tap handler)
/// push a route - there's no router/deep-link infrastructure in this app
/// otherwise (see lib/app/router.dart). Declared in its own file rather
/// than in main.dart so core/ code (push_notification_service.dart,
/// core_providers.dart) can depend on it without importing the app's entry
/// point.
final navigatorKey = GlobalKey<NavigatorState>();
