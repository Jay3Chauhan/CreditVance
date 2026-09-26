import 'package:flutter/foundation.dart';
import '../../../../core/data/mock_seed_data.dart';
import '../../../catalog/domain/entities/catalog_card.dart';
import '../../../wallet/domain/entities/user_card.dart';
import '../../domain/entities/calculation_result.dart';
import '../../domain/reward_engine.dart';

/// Annual rewards simulator. Pure on-device computation: instant, offline,
/// and nothing about the user's spend profile leaves the phone.
class CalculatorProvider extends ChangeNotifier {
  CalculatorProvider() {
    _subject = subjectFromCatalog(MockSeedData.sampleCards.first);
    _recalculate();
  }

  static const double sliderMax = 100000;

  final Map<SpendBucket, double> _monthly = {
    SpendBucket.dining: 8000,
    SpendBucket.travel: 10000,
    SpendBucket.grocery: 6000,
    SpendBucket.shopping: 10000,
    SpendBucket.bills: 4000,
    SpendBucket.other: 8000,
  };

  double monthlyFor(SpendBucket b) => _monthly[b] ?? 0;
  double get monthlyTotal => _monthly.values.fold(0, (a, b) => a + b);

  late RewardSubject _subject;
  RewardSubject get subject => _subject;

  late CalculationResult _result;
  CalculationResult get result => _result;

  List<UserCard> _wallet = const [];

  /// Every wallet card simulated on the same spend profile, best first.
  List<CalculationResult> _showdown = const [];
  List<CalculationResult> get walletShowdown => _showdown;

  void updateWallet(List<UserCard> cards) {
    final changed = cards.length != _wallet.length ||
        !cards.every((c) => _wallet.any((w) => w.id == c.id));
    _wallet = cards;
    if (!changed) return;
    if (_subject.userCardId == null && cards.isNotEmpty && _subject.cardId == MockSeedData.sampleCards.first.id) {
      _subject = subjectFromWallet(cards.first);
    }
    _recalculate();
  }

  void selectCatalogCard(CatalogCard card) {
    _subject = subjectFromCatalog(card);
    _recalculate();
  }

  void selectWalletCard(UserCard card) {
    _subject = subjectFromWallet(card);
    _recalculate();
  }

  void setSpend(SpendBucket bucket, double monthly) {
    final v = monthly.clamp(0, sliderMax).toDouble();
    if (_monthly[bucket] == v) return;
    _monthly[bucket] = v;
    _recalculate();
  }

  void applyPreset(Map<SpendBucket, double> preset) {
    _monthly
      ..clear()
      ..addAll(preset);
    _recalculate();
  }

  static const Map<String, Map<SpendBucket, double>> presets = {
    'Frequent flyer': {
      SpendBucket.dining: 10000,
      SpendBucket.travel: 40000,
      SpendBucket.grocery: 5000,
      SpendBucket.shopping: 8000,
      SpendBucket.bills: 4000,
      SpendBucket.other: 8000,
    },
    'Online shopper': {
      SpendBucket.dining: 6000,
      SpendBucket.travel: 3000,
      SpendBucket.grocery: 8000,
      SpendBucket.shopping: 30000,
      SpendBucket.bills: 5000,
      SpendBucket.other: 5000,
    },
    'Family budget': {
      SpendBucket.dining: 5000,
      SpendBucket.travel: 4000,
      SpendBucket.grocery: 18000,
      SpendBucket.shopping: 8000,
      SpendBucket.bills: 9000,
      SpendBucket.other: 10000,
    },
  };

  void _recalculate() {
    _result = RewardEngine.calculate(_subject, _monthly);
    _showdown = _wallet.map((c) => RewardEngine.calculate(subjectFromWallet(c), _monthly)).toList()
      ..sort((a, b) => b.netBenefit.compareTo(a.netBenefit));
    notifyListeners();
  }

  static RewardSubject subjectFromCatalog(CatalogCard c) => RewardSubject(
        cardId: c.id,
        name: c.shortName,
        slug: c.slug,
        bankName: c.bankName,
        bankLogoUrl: c.bankLogoUrl,
        baseRate: c.baseReturnRate,
        maxRate: c.maxReturnRate,
        annualFee: c.annualFee,
        feeWaiverSpend: c.feeWaiverSpend,
      );

  static RewardSubject subjectFromWallet(UserCard c) => RewardSubject(
        cardId: c.cardId,
        userCardId: c.id,
        name: c.nickname.isNotEmpty ? c.nickname : c.cardName,
        slug: c.cardSlug,
        bankName: c.bankName,
        bankLogoUrl: c.bankLogoUrl,
        baseRate: c.baseReturnRate,
        maxRate: c.maxReturnRate,
        annualFee: c.annualFee,
      );
}
