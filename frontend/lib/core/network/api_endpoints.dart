/// Every endpoint path the app calls, in one place. Datasources reference
/// these constants instead of writing raw strings — so if the backend
/// renames `/topups` to `/top-ups` tomorrow, you fix it here once, instead
/// of hunting through every `XRemoteDataSource` file that happened to call it.
class ApiEndpoints {
  ApiEndpoints._(); // static-only namespace, never instantiated

  // Swap this per environment (dev/staging/prod) — see the note in
  // ApiClient below about injecting this rather than hardcoding it here.
  static const String baseUrl = 'https://api.yourbackend.com';

  // Auth
  static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

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
  static const String me = '/me';
  static const String settings = '/settings';
}