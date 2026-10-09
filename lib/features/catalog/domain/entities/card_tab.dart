/// A reward-earning row from `/cards/{slug}/tabs/earn-categories`.
class EarnRate {
  final String name;
  final String? category;
  final double points;
  final double per;
  final String unit;

  const EarnRate({
    required this.name,
    this.category,
    required this.points,
    required this.per,
    required this.unit,
  });

  /// "25 RPs / ₹150"
  String get label {
    String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
    return '${n(points)} $unit / ₹${n(per)}';
  }

  double get pointsPerHundred => per > 0 ? points / per * 100 : 0;
}

/// Parsed content of a card detail tab.
class CardTab {
  final String name;
  final List<EarnRate> earnRates;
  final List<String> exclusions;
  final List<String> bullets;

  const CardTab({
    required this.name,
    this.earnRates = const [],
    this.exclusions = const [],
    this.bullets = const [],
  });

  bool get isEmpty => earnRates.isEmpty && exclusions.isEmpty && bullets.isEmpty;

  factory CardTab.fromJson(String name, Map<String, dynamic> json) {
    final content = json['content'];
    final tabData = content is Map<String, dynamic>
        ? (content['tabData'] is Map<String, dynamic> ? content['tabData'] as Map<String, dynamic> : content)
        : const <String, dynamic>{};

    final rows = <EarnRate>[];
    final rawRows = tabData['earnRows'];
    if (rawRows is List) {
      for (final r in rawRows.whereType<Map<String, dynamic>>()) {
        rows.add(EarnRate(
          name: r['name']?.toString() ?? 'Spends',
          category: r['category']?.toString(),
          points: (r['points'] as num?)?.toDouble() ?? 0,
          per: (r['per'] as num?)?.toDouble() ?? 100,
          unit: r['unit']?.toString() ?? 'pts',
        ));
      }
    }

    final exclusions = <String>[];
    final rawEx = tabData['exclusions'];
    if (rawEx is List) {
      for (final e in rawEx) {
        exclusions.add(e is Map ? (e['name'] ?? e['category'] ?? '').toString() : e.toString());
      }
    }

    final bullets = <String>[];
    for (final key in ['bullets', 'bullet_points', 'points', 'items']) {
      final raw = tabData[key];
      if (raw is List) bullets.addAll(raw.map((e) => e is Map ? (e['text'] ?? e['name'] ?? '').toString() : e.toString()));
    }

    return CardTab(
      name: name,
      earnRates: rows,
      exclusions: exclusions.where((e) => e.isNotEmpty).toList(),
      bullets: bullets.where((e) => e.isNotEmpty).toList(),
    );
  }
}
