import 'package:flutter/material.dart';
import '../model/app_notification.dart';

/// Mock "Alerts" tab data — payment declines, new-device sign-ins, etc.
/// There's no backend generating real fraud/security events yet (same
/// situation as every other mock dataset in this app), so this is a
/// fixed, hand-written list.
final List<AppNotification> mockAlertNotifications = [
  AppNotification(
    id: 'alert_001',
    category: NotificationCategory.alert,
    title: 'Payment Declined',
    message:
        'Your payment of \$45.00 to Amazon Marketplace was declined due to insufficient funds.',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    icon: Icons.error_outline,
  ),
  AppNotification(
    id: 'alert_002',
    category: NotificationCategory.alert,
    title: 'New Device Sign-in',
    message:
        "Your account was signed into from a new device. If this wasn't you, secure your account.",
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    icon: Icons.security,
  ),
  AppNotification(
  id: 'alert_003',
  category: NotificationCategory.alert,
  title: 'Suspicious Transaction Detected',
  message: 'We noticed unusual activity on your card ending in 4242. Tap to review.',
  timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
  icon: Icons.gpp_maybe_outlined,
  isFraudAlert: true,
),
];