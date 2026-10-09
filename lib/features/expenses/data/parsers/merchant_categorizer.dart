import '../../domain/entities/spend_category.dart';

/// Normalised merchant identity produced by [MerchantCategorizer].
class MerchantInfo {
  final String name;
  final SpendCategory category;

  /// True when matched against the curated brand list (vs. keyword heuristic).
  final bool isKnownBrand;

  const MerchantInfo({required this.name, required this.category, required this.isKnownBrand});
}

class _BrandRule {
  final RegExp pattern;
  final String name;
  final SpendCategory category;

  _BrandRule(String pattern, this.name, this.category) : pattern = RegExp(pattern);
}

class _KeywordRule {
  final RegExp pattern;
  final SpendCategory category;

  _KeywordRule(String pattern, this.category) : pattern = RegExp(pattern);
}

/// On-device first-pass merchant normaliser and categoriser.
///
/// Brand rules match against a compact key (upper-case, alphanumerics only),
/// so `AMAZON PAY INDIA PVT`, `amzn mktp` and `amazon.in` all resolve to Amazon.
/// The backend may later return better enrichments which override these.
class MerchantCategorizer {
  MerchantCategorizer();

  static final RegExp _aggregatorPrefix = RegExp(
    r'^(?:PAYU|RAZORPAY|RAZ|RZP|CCAVENUE|PAYTM|PHONEPE|PAYPAL|CASHFREE|BILLDESK|PINELABS|EZETAP|SQ|PG|GOOGLE)\s*[*\-_/.]+\s*',
  );
  static final RegExp _corporateSuffix = RegExp(
    r'\b(?:PVT|PRIVATE|LTD|LIMITED|LLP|INC|CORP|CORPORATION|INDIA|IN|CO)\b\.?',
  );
  static final RegExp _nonAlnum = RegExp(r'[^A-Z0-9]');
  static final RegExp _trailingIds = RegExp(r'[\s*#\-_/]*\d{3,}$');
  static final RegExp _multiSpace = RegExp(r'\s+');

  static final List<_BrandRule> _brands = [
    // Subscriptions / OTT (checked before generic brands)
    _BrandRule(r'AMAZONPRIME|PRIMEVIDEO', 'Amazon Prime', SpendCategory.subscriptions),
    _BrandRule(r'NETFLIX', 'Netflix', SpendCategory.subscriptions),
    _BrandRule(r'SPOTIFY', 'Spotify', SpendCategory.subscriptions),
    _BrandRule(r'YOUTUBE', 'YouTube Premium', SpendCategory.subscriptions),
    _BrandRule(r'JIOHOTSTAR|HOTSTAR|DISNEY', 'JioHotstar', SpendCategory.subscriptions),
    _BrandRule(r'SONYLIV', 'SonyLIV', SpendCategory.subscriptions),
    _BrandRule(r'ZEE5', 'ZEE5', SpendCategory.subscriptions),
    _BrandRule(r'APPLECOM|ITUNES|APPLESERVICES', 'Apple Services', SpendCategory.subscriptions),
    _BrandRule(r'GOOGLEPLAY|GOOGLEONE', 'Google Play', SpendCategory.subscriptions),
    _BrandRule(r'OPENAI|CHATGPT', 'OpenAI', SpendCategory.subscriptions),
    _BrandRule(r'MICROSOFT|XBOX', 'Microsoft', SpendCategory.subscriptions),
    _BrandRule(r'ADOBE', 'Adobe', SpendCategory.subscriptions),
    _BrandRule(r'LINKEDIN', 'LinkedIn', SpendCategory.subscriptions),
    _BrandRule(r'AUDIBLE', 'Audible', SpendCategory.subscriptions),
    // Quick commerce & groceries (Instamart before Swiggy)
    _BrandRule(r'INSTAMART', 'Swiggy Instamart', SpendCategory.groceries),
    _BrandRule(r'BLINKIT|GROFERS', 'Blinkit', SpendCategory.groceries),
    _BrandRule(r'ZEPTO|KIRANAKART', 'Zepto', SpendCategory.groceries),
    _BrandRule(r'BIGBASKET|INNOVATIVERETAIL|BBNOW', 'BigBasket', SpendCategory.groceries),
    _BrandRule(r'DMART|AVENUESUPERMART', 'DMart', SpendCategory.groceries),
    _BrandRule(r'JIOMART', 'JioMart', SpendCategory.groceries),
    _BrandRule(r'MORERETAIL|MORESUPERMARKET', 'More Supermarket', SpendCategory.groceries),
    _BrandRule(r'SPENCER', "Spencer's", SpendCategory.groceries),
    _BrandRule(r'NATURESBASKET', "Nature's Basket", SpendCategory.groceries),
    // Food delivery & dining
    _BrandRule(r'SWIGGY|BUNDLTECHNOLOGIES', 'Swiggy', SpendCategory.dining),
    _BrandRule(r'ZOMATO', 'Zomato', SpendCategory.dining),
    _BrandRule(r'STARBUCKS|TATASTARBUCKS', 'Starbucks', SpendCategory.dining),
    _BrandRule(r'DOMINOS|JUBILANTFOOD', "Domino's", SpendCategory.dining),
    _BrandRule(r'MCDONALD|HARDCASTLE|WESTLIFE', "McDonald's", SpendCategory.dining),
    _BrandRule(r'KFC|DEVYANI', 'KFC', SpendCategory.dining),
    _BrandRule(r'PIZZAHUT', 'Pizza Hut', SpendCategory.dining),
    _BrandRule(r'BURGERKING|RESTAURANTBRANDSASIA', 'Burger King', SpendCategory.dining),
    _BrandRule(r'HALDIRAM', "Haldiram's", SpendCategory.dining),
    _BrandRule(r'CHAAYOS', 'Chaayos', SpendCategory.dining),
    _BrandRule(r'THIRDWAVE', 'Third Wave Coffee', SpendCategory.dining),
    _BrandRule(r'EATCLUB|BOX8', 'EatClub', SpendCategory.dining),
    // Shopping
    _BrandRule(r'AMAZON|AMZN', 'Amazon', SpendCategory.shopping),
    _BrandRule(r'FLIPKART|FKRT', 'Flipkart', SpendCategory.shopping),
    _BrandRule(r'MYNTRA', 'Myntra', SpendCategory.shopping),
    _BrandRule(r'AJIO', 'AJIO', SpendCategory.shopping),
    _BrandRule(r'NYKAA', 'Nykaa', SpendCategory.shopping),
    _BrandRule(r'MEESHO', 'Meesho', SpendCategory.shopping),
    _BrandRule(r'TATACLIQ', 'Tata CLiQ', SpendCategory.shopping),
    _BrandRule(r'CROMA|INFINITIRETAIL', 'Croma', SpendCategory.shopping),
    _BrandRule(r'RELIANCEDIGITAL', 'Reliance Digital', SpendCategory.shopping),
    _BrandRule(r'RELIANCETRENDS', 'Reliance Trends', SpendCategory.shopping),
    _BrandRule(r'DECATHLON', 'Decathlon', SpendCategory.shopping),
    _BrandRule(r'IKEA', 'IKEA', SpendCategory.shopping),
    _BrandRule(r'LIFESTYLE', 'Lifestyle', SpendCategory.shopping),
    _BrandRule(r'SHOPPERSSTOP', 'Shoppers Stop', SpendCategory.shopping),
    // Travel & mobility
    _BrandRule(r'UBER', 'Uber', SpendCategory.travel),
    _BrandRule(r'OLACABS|ANITECHNOLOGIES|^OLA', 'Ola', SpendCategory.travel),
    _BrandRule(r'RAPIDO|ROPPEN', 'Rapido', SpendCategory.travel),
    _BrandRule(r'IRCTC', 'IRCTC', SpendCategory.travel),
    _BrandRule(r'MAKEMYTRIP|^MMT', 'MakeMyTrip', SpendCategory.travel),
    _BrandRule(r'GOIBIBO', 'Goibibo', SpendCategory.travel),
    _BrandRule(r'CLEARTRIP', 'Cleartrip', SpendCategory.travel),
    _BrandRule(r'EASEMYTRIP', 'EaseMyTrip', SpendCategory.travel),
    _BrandRule(r'IXIGO', 'ixigo', SpendCategory.travel),
    _BrandRule(r'INDIGO|INTERGLOBE', 'IndiGo', SpendCategory.travel),
    _BrandRule(r'AIRINDIA', 'Air India', SpendCategory.travel),
    _BrandRule(r'AKASA', 'Akasa Air', SpendCategory.travel),
    _BrandRule(r'SPICEJET', 'SpiceJet', SpendCategory.travel),
    _BrandRule(r'AIRBNB', 'Airbnb', SpendCategory.travel),
    _BrandRule(r'^OYO|ORAVEL', 'OYO', SpendCategory.travel),
    _BrandRule(r'BOOKINGCOM', 'Booking.com', SpendCategory.travel),
    _BrandRule(r'AGODA', 'Agoda', SpendCategory.travel),
    _BrandRule(r'MARRIOTT', 'Marriott', SpendCategory.travel),
    _BrandRule(r'TAJHOTEL|IHCL', 'Taj Hotels', SpendCategory.travel),
    _BrandRule(r'FASTAG|NETCTOLL', 'FASTag', SpendCategory.travel),
    // Fuel
    _BrandRule(r'HPCL|HINDUSTANPETROLEUM', 'HP Petrol', SpendCategory.fuel),
    _BrandRule(r'IOCL|INDIANOIL', 'Indian Oil', SpendCategory.fuel),
    _BrandRule(r'BPCL|BHARATPETROLEUM', 'Bharat Petroleum', SpendCategory.fuel),
    _BrandRule(r'SHELL', 'Shell', SpendCategory.fuel),
    _BrandRule(r'NAYARA', 'Nayara Energy', SpendCategory.fuel),
    _BrandRule(r'JIOBP', 'Jio-bp', SpendCategory.fuel),
    // Entertainment
    _BrandRule(r'BOOKMYSHOW|BIGTREE', 'BookMyShow', SpendCategory.entertainment),
    _BrandRule(r'PVR|INOX', 'PVR INOX', SpendCategory.entertainment),
    _BrandRule(r'DISTRICTAPP|DISTRICTBYZOMATO', 'District', SpendCategory.entertainment),
    _BrandRule(r'STEAMPOWERED|STEAMGAMES|VALVECORP', 'Steam', SpendCategory.entertainment),
    _BrandRule(r'PLAYSTATION|SONYINTERACTIVE', 'PlayStation', SpendCategory.entertainment),
    // Utilities & telecom
    _BrandRule(r'AIRTEL|BHARTI', 'Airtel', SpendCategory.utilities),
    _BrandRule(r'RELIANCEJIO|^JIO', 'Jio', SpendCategory.utilities),
    _BrandRule(r'VODAFONE|VODAIDEA', 'Vi', SpendCategory.utilities),
    _BrandRule(r'BSNL', 'BSNL', SpendCategory.utilities),
    _BrandRule(r'TATAPLAY|TATASKY', 'Tata Play', SpendCategory.utilities),
    _BrandRule(r'BESCOM', 'BESCOM', SpendCategory.utilities),
    _BrandRule(r'MSEDCL|MAHADISCOM', 'MSEDCL', SpendCategory.utilities),
    _BrandRule(r'TATAPOWER', 'Tata Power', SpendCategory.utilities),
    _BrandRule(r'ADANIELECTRICITY|ADANIENERGY', 'Adani Electricity', SpendCategory.utilities),
    _BrandRule(r'BSES', 'BSES', SpendCategory.utilities),
    _BrandRule(r'TORRENTPOWER', 'Torrent Power', SpendCategory.utilities),
    _BrandRule(r'MAHANAGARGAS|INDRAPRASTHAGAS', 'Piped Gas', SpendCategory.utilities),
    _BrandRule(r'ACTFIBERNET|HATHWAY', 'Broadband', SpendCategory.utilities),
    // Health
    _BrandRule(r'APOLLO', 'Apollo', SpendCategory.health),
    _BrandRule(r'PHARMEASY', 'PharmEasy', SpendCategory.health),
    _BrandRule(r'TATA1MG|^1MG', 'Tata 1mg', SpendCategory.health),
    _BrandRule(r'NETMEDS', 'Netmeds', SpendCategory.health),
    _BrandRule(r'MEDPLUS', 'MedPlus', SpendCategory.health),
    _BrandRule(r'PRACTO', 'Practo', SpendCategory.health),
    _BrandRule(r'CULTFIT|CUREFIT', 'cult.fit', SpendCategory.health),
    // Education
    _BrandRule(r'BYJU', "BYJU'S", SpendCategory.education),
    _BrandRule(r'UNACADEMY|SORTINGHAT', 'Unacademy', SpendCategory.education),
    _BrandRule(r'COURSERA', 'Coursera', SpendCategory.education),
    _BrandRule(r'UDEMY', 'Udemy', SpendCategory.education),
    _BrandRule(r'UPGRAD', 'upGrad', SpendCategory.education),
    _BrandRule(r'PHYSICSWALLAH', 'Physics Wallah', SpendCategory.education),
    // Rent & housing
    _BrandRule(r'NOBROKER', 'NoBroker', SpendCategory.rent),
    _BrandRule(r'HOUSINGCOM', 'Housing.com', SpendCategory.rent),
    _BrandRule(r'MYGATE', 'MyGate', SpendCategory.rent),
    // Wallet loads
    _BrandRule(r'PAYTMWALLET|ADDMONEY|WALLETLOAD|AMAZONPAYBALANCE', 'Wallet Top-up', SpendCategory.wallet),
  ];

  static final List<_KeywordRule> _keywords = [
    _KeywordRule(r'\b(RESTAURANT|CAFE|COFFEE|FOODS?|KITCHEN|BAKERY|BAKERS|DHABA|BISTRO|EATS|BIRYANI|PIZZA|SWEETS)\b',
        SpendCategory.dining),
    _KeywordRule(r'\b(SUPERMARKET|HYPERMARKET|GROCERY|GROCERIES|GROCER|KIRANA|PROVISION|FRESH|DAIRY)\b',
        SpendCategory.groceries),
    _KeywordRule(r'\b(PETROL|PETROLEUM|FUELS?|FILLING|SERVICE STATION|PUMP)\b', SpendCategory.fuel),
    _KeywordRule(r'\b(HOSPITAL|CLINIC|PHARMACY|PHARMA|MEDICAL|MEDICOS|CHEMIST|DIAGNOSTICS?|HEALTHCARE|DENTAL|LABS?)\b',
        SpendCategory.health),
    _KeywordRule(r'\b(HOTELS?|RESORTS?|TRAVELS?|AIRLINES?|AIRWAYS|RAILWAYS?|TOURS|CABS?|TAXI|PARKING|TOLL)\b',
        SpendCategory.travel),
    _KeywordRule(r'\b(SCHOOL|COLLEGE|UNIVERSITY|ACADEMY|TUITION|EDUCATION|INSTITUTE|CLASSES)\b',
        SpendCategory.education),
    _KeywordRule(r'\b(ELECTRICITY|POWER|GAS|WATER|BROADBAND|TELECOM|RECHARGE|DTH|POSTPAID|PREPAID)\b',
        SpendCategory.utilities),
    _KeywordRule(r'\b(CINEMAS?|MOVIES?|MULTIPLEX|GAMING|GAMES|CLUB|EVENTS?)\b', SpendCategory.entertainment),
    _KeywordRule(r'\b(RENT|PROPERTY|SOCIETY|MAINTENANCE|APARTMENTS?)\b', SpendCategory.rent),
    _KeywordRule(r'\b(FASHION|APPAREL|GARMENTS|RETAIL|STORES?|MART|MALL|ELECTRONICS|JEWELL?ERS?|FOOTWEAR|BOUTIQUE)\b',
        SpendCategory.shopping),
    _KeywordRule(r'\b(WALLET|TOP ?UP)\b', SpendCategory.wallet),
  ];

  static final RegExp _vpaRe = RegExp(r'^([a-z0-9._\-]+)@([a-z0-9]+)$', caseSensitive: false);

  /// Builds an upper-case alphanumeric key for brand matching.
  static String compactKey(String raw) {
    var s = raw.toUpperCase().trim();
    s = s.replaceFirst(_aggregatorPrefix, '');
    return s.replaceAll(_nonAlnum, '');
  }

  /// Normalises and categorises a raw merchant string extracted from an SMS.
  MerchantInfo categorize(String raw) {
    final vpa = _vpaRe.firstMatch(raw.trim());
    final source = vpa != null ? vpa.group(1)!.replaceAll(RegExp(r'[._\-]'), ' ') : raw;
    final key = compactKey(source);

    for (final rule in _brands) {
      if (rule.pattern.hasMatch(key)) {
        return MerchantInfo(name: rule.name, category: rule.category, isKnownBrand: true);
      }
    }

    if (vpa != null) {
      return const MerchantInfo(name: 'UPI Merchant', category: SpendCategory.other, isKnownBrand: false);
    }

    final spaced = source.toUpperCase().replaceFirst(_aggregatorPrefix, '');
    for (final rule in _keywords) {
      if (rule.pattern.hasMatch(spaced)) {
        return MerchantInfo(name: displayName(raw), category: rule.category, isKnownBrand: false);
      }
    }
    return MerchantInfo(name: displayName(raw), category: SpendCategory.other, isKnownBrand: false);
  }

  /// Converts `SHREE GANESH MEDICOS PVT LTD 0042` into `Shree Ganesh Medicos`.
  static String displayName(String raw) {
    var s = raw.toUpperCase().trim().replaceFirst(_aggregatorPrefix, '');
    s = s.replaceAll(_trailingIds, '');
    s = s.replaceAll(_corporateSuffix, ' ');
    s = s.replaceAll(RegExp(r'[*_#]+'), ' ').replaceAll(_multiSpace, ' ').trim();
    if (s.isEmpty) s = raw.trim().toUpperCase();
    final words = s.split(' ').where((w) => w.isNotEmpty).map((w) {
      if (w.length <= 3 && !w.contains(RegExp(r'[AEIOU]'))) return w;
      return w[0] + w.substring(1).toLowerCase();
    });
    final title = words.join(' ');
    return title.length > 28 ? '${title.substring(0, 27).trimRight()}…' : title;
  }
}
