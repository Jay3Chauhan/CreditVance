/// Centralized UI strings and labels for CardSage.
class AppStrings {
  const AppStrings._();

  static const String appName = 'CardSage';
  static const String appTagline = 'Smart Credit Card Advisor & Vault';

  // Navigation Items
  static const String navAdvisor = 'Advisor';
  static const String navWallet = 'Vault';
  static const String navCatalog = 'Explore';
  static const String navCalculator = 'Calculator';
  static const String navProfile = 'Account';

  // Advisor
  static const String advisorTitle = 'Smart Advisor';
  static const String advisorSubtitle = 'Maximize your returns at checkout';
  static const String selectCategory = 'Where are you spending?';
  static const String spendAmount = 'Transaction Amount';
  static const String internationalSpend = 'International Transaction (Forex)';
  static const String recommendCardCta = 'Find Best Card';
  static const String topRecommendation = 'Top Recommended Card';
  static const String estimatedReturn = 'Estimated Return';

  // Vault / Wallet
  static const String walletTitle = 'Zero-Knowledge Vault';
  static const String walletSubtitle = 'Hardware-encrypted on your device';
  static const String addCardCta = 'Add New Card';
  static const String tapToReveal = 'Tap to unlock card numbers';
  static const String copyCardNumber = 'Copy Card Number';
  static const String cardCopiedToast = 'Card copied! Auto-clears in 30s';
  static const String biometricReason = 'Authenticate to access card vault';

  // Catalog
  static const String catalogTitle = 'Cards Catalog';
  static const String catalogSubtitle = 'Explore 731+ Indian Credit Cards';
  static const String searchPlaceholder = 'Search cards, banks or perks...';
  static const String filterByBank = 'Bank';
  static const String filterByNetwork = 'Network';
  static const String filterByFee = 'Annual Fee';
  static const String sortBy = 'Sort By';

  // Calculator
  static const String calculatorTitle = 'Reward Calculator';
  static const String calculatorSubtitle = 'Simulate annual cashback & reward points';
  static const String annualSpend = 'Monthly Spend by Category';
  static const String calculateCta = 'Calculate Rewards';

  // Errors & States
  static const String generalError = 'Something went wrong. Please try again.';
  static const String offlineMessage = 'You are currently offline. Showing cached cards.';
  static const String retry = 'Retry';
  static const String emptyWallet = 'No cards added to your vault yet.';
  static const String emptyWalletPrompt = 'Add your credit cards to receive personalized recommendations and secure one-tap copy at checkout.';
}
