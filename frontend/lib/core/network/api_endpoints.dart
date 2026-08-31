import 'package:flutter/foundation.dart' show kIsWeb;

class ApiEndpoints {
  ApiEndpoints._(); // static-only namespace, never instantiated

  // Android emulator: 10.0.2.2 is a special alias the emulator maps to the
  // host machine's own 127.0.0.1 — so `php artisan serve` (which binds
  // 127.0.0.1:8000 by default) is reachable as-is, no --host flag needed.
  // Flutter web runs in a real browser, which has no such alias — there,
  // `localhost` (the host machine itself) is what actually reaches it.
  // This will need to change again for a physical device (host's LAN IP)
  // or iOS simulator (localhost works directly there, same as web).
  static String get baseUrl =>
      kIsWeb ? 'http://localhost:8000/api/v1' : 'http://10.0.2.2:8000/api/v1';

  // Auth
  static const String register = '/register';
  static const String login = '/login';
  static const String me = '/me';
  static const String logout = '/logout';

  // Top-up feature
  static const String paymentMethods = '/payment-methods';
  static const String topups = '/topups';

  // Transactions
  static String transactionDetail(String id) => '/transactions/$id';
  static String reportTransactionIssue(String id) => '/transactions/$id/report';

  // Wallet
  static const String wallets = '/wallets';
  static const String defaultWallet = '/wallets/default';
  static const String defaultWalletTransactions = '/wallets/default/transactions';
  static String walletTransactions(String currency) => '/wallets/$currency/transactions';
  
  // Users
  static const String userSearch = '/users/search';
  // Transfers
  static const String transfers = '/transfers';

  // Fraud alerts
  static String fraudAlert(String transactionId) => '/fraud-alerts/$transactionId';
  static String fraudAlertRespond(String transactionId) => '/fraud-alerts/$transactionId/respond';

  // Profile & settings
  static const String settings = '/settings';
}