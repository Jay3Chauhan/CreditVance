/// API endpoints and network configuration.
class ApiEndpoints {
  const ApiEndpoints._();

  /// Override at build time: `--dart-define=API_BASE_URL=https://staging.example.com/api/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://credit.jaychauhan.tech/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 12);

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String refresh = '/auth/refresh';
  static const String passwordForgot = '/auth/password/forgot';
  static const String passwordReset = '/auth/password/reset';

  // Catalog
  static const String cards = '/cards';
  static String cardDetail(String slug) => '/cards/$slug';
  static String cardTab(String slug, String tabName) => '/cards/$slug/tabs/$tabName';

  // Wallet
  static const String userCards = '/user-cards';
  static String userCardById(int id) => '/user-cards/$id';
  static const String walletOrder = '/wallet/order';
  static const String walletInsights = '/wallet/insights';

  // Advisor & calculator
  static const String advisorRecommend = '/advisor/recommend';
  static const String calculator = '/calculator/calculate';
  static const String calculatorAnnual = '/calculator/annual';

  // Content platform
  static const String home = '/home';
  static const String banners = '/banners';
  static String bannerTrack(int id) => '/banners/$id/track';
  static const String promotions = '/promotions';
  static String promotion(String slug) => '/promotions/$slug';
  static String promotionTrack(int id) => '/promotions/$id/track';
  static const String compare = '/cards/compare';
  static const String searchSuggest = '/search/suggest';
  static const String savedCards = '/saved-cards';
  static String savedCard(int cardId) => '/saved-cards/$cardId';
  static const String faq = '/meta/faq';
  static const String legal = '/meta/legal';
  static const String metaConfig = '/meta/config';

  // Taxonomies
  static const String banks = '/banks';
  static const String categories = '/categories';

  // SMS Expense Tracking (structured fields only — raw SMS bodies never leave the device)
  static const String expenseTransactionsBatch = '/expenses/transactions/batch';
  static const String expenseTransactions = '/expenses/transactions';
  static String expenseTransactionByHash(String dedupeHash) => '/expenses/transactions/$dedupeHash';
  static const String expenseConsent = '/expenses/consent';
  static const String expenseData = '/expenses/data';
  static const String expenseMilestones = '/expenses/milestones';
  static const String expenseAnalyticsSummary = '/expenses/analytics/summary';
  static const String expenseSenderRegistry = '/expenses/sender-registry';

  // Notifications & Reminders
  static const String notificationDeviceToken = '/notifications/device-token';
  static const String notificationStatus = '/notifications/status';
  static const String notificationPreferences = '/notifications/preferences';
  static const String notificationTest = '/notifications/test';
  static const String notificationHistory = '/notifications/history';
  static const String notificationReminders = '/notifications/reminders';

  static const int pageSize = 20;
}
