import 'package:flutter/material.dart';

import '../../catalog/domain/entities/catalog_card.dart';

/// Shared tap target for banners, promotions, collections and quick actions.
class ContentAction {
  final String type;
  final String? target;
  final String? label;

  const ContentAction({required this.type, this.target, this.label});

  factory ContentAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContentAction(type: 'none');
    return ContentAction(
      type: json['type'] as String? ?? 'none',
      target: json['target'] as String?,
      label: json['label'] as String?,
    );
  }

  bool get isNone => type == 'none' || (target == null && type != 'none');
}

class AppBanner {
  final int id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? badgeText;
  final String? backgroundColor;
  final String? accentColor;
  final ContentAction action;

  const AppBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.badgeText,
    this.backgroundColor,
    this.accentColor,
    required this.action,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json) => AppBanner(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        imageUrl: json['image_url'] as String?,
        badgeText: json['badge_text'] as String?,
        backgroundColor: json['background_color'] as String?,
        accentColor: json['accent_color'] as String?,
        action: ContentAction.fromJson(json['action'] as Map<String, dynamic>?),
      );

  Color get background {
    final parsed = parseHex(backgroundColor);
    return parsed.a == 0 ? const Color(0xFF0F2744) : parsed;
  }

  Color get accent {
    final parsed = parseHex(accentColor);
    return parsed.a == 0 ? const Color(0xFFF4C430) : parsed;
  }
}

class Promotion {
  final int id;
  final String slug;
  final String title;
  final String summary;
  final String? description;
  final String? badge;
  final String promoType;
  final String? highlightValue;
  final String? terms;
  final String? categorySlug;
  final String? cardSlug;
  final ContentAction action;

  const Promotion({
    required this.id,
    required this.slug,
    required this.title,
    required this.summary,
    this.description,
    this.badge,
    required this.promoType,
    this.highlightValue,
    this.terms,
    this.categorySlug,
    this.cardSlug,
    required this.action,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) => Promotion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        description: json['description'] as String?,
        badge: json['badge'] as String?,
        promoType: json['promo_type'] as String? ?? 'editorial',
        highlightValue: json['highlight_value'] as String?,
        terms: json['terms'] as String?,
        categorySlug: json['category_slug'] as String?,
        cardSlug: json['card_slug'] as String?,
        action: ContentAction.fromJson(json['action'] as Map<String, dynamic>?),
      );
}

class HomeCollection {
  final String key;
  final String title;
  final String? subtitle;
  final ContentAction action;
  final List<CatalogCard> cards;

  const HomeCollection({
    required this.key,
    required this.title,
    this.subtitle,
    required this.action,
    this.cards = const [],
  });
}

class QuickAction {
  final String key;
  final String title;
  final String? subtitle;
  final String? iconKey;
  final ContentAction action;

  const QuickAction({
    required this.key,
    required this.title,
    this.subtitle,
    this.iconKey,
    required this.action,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction(
        key: json['key'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        iconKey: json['icon_key'] as String?,
        action: ContentAction.fromJson(json['action'] as Map<String, dynamic>?),
      );
}

class HomeFeed {
  final List<AppBanner> heroBanners;
  final List<AppBanner> stripBanners;
  final List<Promotion> featuredPromotions;
  final List<CatalogCard> popularCards;
  final List<HomeCollection> collections;
  final List<QuickAction> quickActions;

  const HomeFeed({
    this.heroBanners = const [],
    this.stripBanners = const [],
    this.featuredPromotions = const [],
    this.popularCards = const [],
    this.collections = const [],
    this.quickActions = const [],
  });

  bool get isEmpty =>
      heroBanners.isEmpty &&
      stripBanners.isEmpty &&
      featuredPromotions.isEmpty &&
      popularCards.isEmpty &&
      collections.isEmpty &&
      quickActions.isEmpty;
}

class CompareRow {
  final String key;
  final String label;
  final String better;
  final Map<String, num?> values;
  final String? winnerSlug;

  const CompareRow({
    required this.key,
    required this.label,
    required this.better,
    required this.values,
    this.winnerSlug,
  });
}

class CompareCategoryRate {
  final String categorySlug;
  final Map<String, num?> rates;
  final String? winnerSlug;

  const CompareCategoryRate({required this.categorySlug, required this.rates, this.winnerSlug});
}

class CardCompareResult {
  final List<CompareRow> rows;
  final List<CompareCategoryRate> categoryRates;

  const CardCompareResult({this.rows = const [], this.categoryRates = const []});
}

class FaqItem {
  final String id;
  final String topic;
  final String question;
  final String answer;

  const FaqItem({required this.id, required this.topic, required this.question, required this.answer});

  factory FaqItem.fromJson(Map<String, dynamic> json) => FaqItem(
        id: json['id'] as String? ?? '',
        topic: json['topic'] as String? ?? 'general',
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );
}

class LegalLinks {
  final String privacyPolicyUrl;
  final String termsUrl;
  final String? deletionUrl;
  final String? contactEmail;

  const LegalLinks({
    required this.privacyPolicyUrl,
    required this.termsUrl,
    this.deletionUrl,
    this.contactEmail,
  });
}

class AppConfig {
  final bool maintenanceMode;
  final String? maintenanceMessage;

  const AppConfig({this.maintenanceMode = false, this.maintenanceMessage});
}

class DueReminder {
  final String nickname;
  final String cardTitle;
  final String bankName;
  final int? daysUntilDue;
  final String message;

  const DueReminder({
    required this.nickname,
    required this.cardTitle,
    required this.bankName,
    this.daysUntilDue,
    required this.message,
  });
}

class CategoryPick {
  final String categorySlug;
  final String? iconKey;
  final double ratePercent;
  final String? nickname;

  const CategoryPick({
    required this.categorySlug,
    this.iconKey,
    required this.ratePercent,
    this.nickname,
  });
}

class WalletInsights {
  final int cardCount;
  final double totalRenewalFee;
  final int lifetimeFreeCount;
  final int loungeCardCount;
  final DueReminder? nextDue;
  final List<CategoryPick> categoryPicks;
  final String? emptyMessage;

  const WalletInsights({
    this.cardCount = 0,
    this.totalRenewalFee = 0,
    this.lifetimeFreeCount = 0,
    this.loungeCardCount = 0,
    this.nextDue,
    this.categoryPicks = const [],
    this.emptyMessage,
  });
}

class SearchSuggestion {
  final int id;
  final String slug;
  final String title;
  final String? displayName;
  final String bankName;
  final String? imageUrl;

  const SearchSuggestion({
    required this.id,
    required this.slug,
    required this.title,
    this.displayName,
    required this.bankName,
    this.imageUrl,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) => SearchSuggestion(
        id: (json['id'] as num?)?.toInt() ?? 0,
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? 'Card',
        displayName: json['display_name'] as String?,
        bankName: json['bank_name'] as String? ?? '',
        imageUrl: json['card_image_url'] as String?,
      );

  String get label {
    final d = displayName?.trim();
    if (d != null && d.isNotEmpty) return d;
    return title;
  }
}

Color parseHex(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0x00000000);
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  final value = int.tryParse(h, radix: 16);
  if (value == null) return const Color(0x00000000);
  return Color(value);
}
