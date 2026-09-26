/// Centralized product copy for CreditVance.
class AppStrings {
  const AppStrings._();

  static const String appName = 'CreditVance';
  static const String appTagline = 'The right card, every checkout.';
  static const String appVersion = '2.0.0';

  // Navigation
  static const String navHome = 'Home';
  static const String navWallet = 'Wallet';
  static const String navExplore = 'Explore';
  static const String navRewards = 'Rewards';
  static const String navProfile = 'Account';

  // Home / advisor
  static const String homeQuestion = 'Where are you paying?';
  static const String homeAmount = 'Amount';
  static const String homeInternational = 'Paying abroad';
  static const String homeInternationalHint = 'Accounts for forex markup';
  static const String homeBestCard = 'Best card for this';
  static const String homeAlternatives = 'Other options';
  static const String homeInsights = 'Smart tips';
  static const String homeBenchmark = 'Best in market';

  // Wallet
  static const String walletTitle = 'Wallet';
  static const String walletEmptyTitle = 'Your wallet is empty';
  static const String walletEmptyBody =
      'Add a card once and copy its number at checkout with a fingerprint — stored only in your phone\'s secure hardware.';
  static const String walletAddFirst = 'Add your first card';
  static const String walletLoadSamples = 'Try with sample cards';
  static const String copyNumber = 'Copy number';
  static const String reveal = 'Reveal';
  static const String hide = 'Hide';
  static const String biometricCopyReason = 'Confirm it\'s you to copy the card number';
  static const String biometricRevealReason = 'Confirm it\'s you to view card details';
  static const String biometricUnlockReason = 'Unlock CreditVance';

  // Explore
  static const String exploreTitle = 'Explore';
  static const String exploreSearchHint = 'Search cards or banks';

  // Rewards
  static const String rewardsTitle = 'Rewards';
  static const String rewardsSubtitle = 'See what a card earns on your monthly spends';

  // Security copy
  static const String zeroKnowledgeNote =
      'Card number and CVV are encrypted in your phone\'s secure hardware (Android Keystore / Secure Enclave). They never leave this device.';

  // Errors
  static const String generalError = 'Something went wrong. Please try again.';
  static const String offlineMessage = 'You\'re offline. Showing saved data.';
  static const String retry = 'Try again';
}
