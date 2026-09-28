import 'package:fintech_wallet/core/services/app_lock_controller.dart';
import 'package:fintech_wallet/features/notifications/data/datasource/device_token_remote_datasource.dart';
import 'package:fintech_wallet/features/notifications/data/model/app_notification.dart';
import 'package:fintech_wallet/features/notifications/presentation/screen/notifications_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const _highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'Important notifications',
  description: 'Payment and account alerts that need your attention.',
  importance: Importance.high,
);

/// Runs in a separate background isolate with no prior Flutter/plugin
/// initialization, so it must re-initialize Firebase itself. Top-level (not
/// a method) and `@pragma('vm:entry-point')` are both required by
/// `firebase_messaging` so the Dart compiler doesn't strip it and the
/// engine can find it when relaunching this isolate.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

/// Wires up FCM: permission + token registration with the backend,
/// foreground display (Android hides an FCM `notification` payload from the
/// system tray unless the app is backgrounded/terminated, so the foreground
/// case needs a manually-posted local notification), and tap-to-open
/// navigation via the app's [navigatorKey].
class PushNotificationService {
  final DeviceTokenRemoteDataSource _dataSource;
  final GlobalKey<NavigatorState> _navigatorKey;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// firebase_messaging ships no plugin implementation for Windows or Linux
  /// (only Android, iOS, macOS and web) - calling any FirebaseMessaging API
  /// on those platforms throws a MissingPluginException. This app's
  /// firebase_options.dart does configure Windows, but only for the
  /// Firebase features that *do* support it there (core/auth/storage/
  /// firestore); messaging is not one of them, so every entry point into
  /// this class must check this first rather than rely on a caught
  /// exception after the fact.
  static bool get isSupportedPlatform {
    if (kIsWeb) return true;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  PushNotificationService(
    this._dataSource, {
    required GlobalKey<NavigatorState> navigatorKey,
  }) : _navigatorKey = navigatorKey;

  Future<void> initialize({
    required void Function(AppNotification notification) onForegroundMessage,
  }) async {
    if (_initialized) return;
    _initialized = true;
    if (!isSupportedPlatform) return;
    await FirebaseMessaging.instance.requestPermission();

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _openNotificationsScreen(pushType: response.payload),
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_highImportanceChannel);

    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
      onForegroundMessage(AppNotification.fromPush(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => _openNotificationsScreen(pushType: message.data['type']),
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((refreshedToken) {
      _dataSource.register(token: refreshedToken, platform: 'android');
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _openNotificationsScreen(pushType: initialMessage.data['type']);
    }
  }

  Future<void> registerToken() async {
    if (!isSupportedPlatform) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _dataSource.register(token: token, platform: 'android');
    }

  }

  Future<void> unregisterToken() async {
    if (!isSupportedPlatform) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _dataSource.unregister(token: token);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final body = notification.body ?? '';
    final amount = message.data['amount'];
    final currency = message.data['currency'];

    // Bolds "<amount> <currency>" inside the body - e.g. "You sent *10 USD*
    // to lavara." Only possible via BigTextStyleInformation's expanded
    // (long-form) text, and only for this foreground/manually-shown
    // notification: a backgrounded/terminated app's notification is
    // auto-posted by Android straight from the raw FCM payload, which has
    // no equivalent style hook, so that one stays plain text regardless.
    // The collapsed heads-up line is always plain too - only the expanded
    // form supports this.
    final styleInformation = (amount is String && currency is String)
        ? BigTextStyleInformation(
            body.replaceFirst('$amount $currency', '<b>$amount $currency</b>'),
            htmlFormatBigText: true,
          )
        : null;

    final type = message.data['type'];

    _local.show(
      id: message.hashCode,
      title: notification.title,
      body: body,
      // Carried through to onDidReceiveNotificationResponse, which (unlike
      // onMessageOpenedApp/getInitialMessage) only gets this plain string
      // back, not the original RemoteMessage - so this is how a foreground
      // tap still knows which tab to open to.
      payload: type is String ? type : null,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _highImportanceChannel.id,
          _highImportanceChannel.name,
          channelDescription: _highImportanceChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: styleInformation,
        ),
      ),
    );
  }

  /// Transaction-triggered pushes (top-up, transfer) belong on the
  /// Transactions tab, not Alerts - Alerts is for fraud/security items, and
  /// today every real push this app sends is a transaction one. Anything
  /// else (an unrecognized or absent type - e.g. a future fraud-alert push)
  /// falls back to Alerts.
  static const _transactionPushTypes = {'topup', 'transfer_in', 'transfer_out'};

  void _openNotificationsScreen({String? pushType}) {
    final tabIndex = _transactionPushTypes.contains(pushType) ? 1 : 0;

    // Deliberately just opens the Notifications screen, not the specific
    // transaction - the app has no deep-link/routing infrastructure today
    // (see lib/app/router.dart, and every other screen navigates via plain
    // Navigator.push rather than named routes), and building that is out
    // of scope here.
    //
    // Routed through guardNavigation (NOV-18) so a notification tap that
    // resumes the app can't push authenticated content on top of an
    // active biometric re-lock - it's deferred until the lock resolves,
    // or dropped if it resolves via logout instead.
    guardNavigation(() {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(initialTabIndex: tabIndex),
        ),
      );
    });
  }
}
