class ApiEndpoints {
  ApiEndpoints._(); // static-only namespace, never instantiated

  // Android emulator only: 10.0.2.2 is a special alias the emulator maps
  // to the host machine's own 127.0.0.1 — so `php artisan serve` (which
  // binds 127.0.0.1:8000 by default) is reachable as-is, no --host flag
  // needed. This will need to change for a physical device (host's LAN IP)
  // or iOS simulator (localhost works directly there).
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

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

  // Transfers
  static const String defaultWallet = '/wallets/default';
  static const String transfers = '/transfers';

  // Fraud alerts
  static String fraudAlert(String transactionId) => '/fraud-alerts/$transactionId';
  static String fraudAlertRespond(String transactionId) => '/fraud-alerts/$transactionId/respond';

  // Profile & settings
  static const String settings = '/settings';
}