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

  // Catalog
  static const String cards = '/cards';
  static String cardDetail(String slug) => '/cards/$slug';
  static String cardTab(String slug, String tabName) => '/cards/$slug/tabs/$tabName';

  // Wallet
  static const String userCards = '/user-cards';
  static String userCardById(int id) => '/user-cards/$id';

  // Advisor & calculator
  static const String advisorRecommend = '/advisor/recommend';
  static const String calculator = '/calculator/calculate';

  // Taxonomies
  static const String banks = '/banks';
  static const String categories = '/categories';

  static const int pageSize = 20;
}
