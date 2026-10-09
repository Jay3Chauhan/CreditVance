import '../../domain/entities/spend_category.dart';

/// Server-side merchant/category enrichment for one record.
class TransactionEnrichment {
  final String dedupeHash;
  final String? merchantName;
  final SpendCategory? category;

  const TransactionEnrichment({required this.dedupeHash, this.merchantName, this.category});
}

/// Response of `POST /expenses/transactions/batch`.
class BatchIngestResultModel {
  /// Hashes newly stored by the server.
  final List<String> accepted;

  /// Hashes the server already had (idempotent replay) — also acknowledged.
  final List<String> duplicates;

  /// Hashes the server refused (validation); dropped from the retry queue.
  final List<String> rejected;
  final List<TransactionEnrichment> enrichments;

  const BatchIngestResultModel({
    required this.accepted,
    required this.duplicates,
    required this.rejected,
    required this.enrichments,
  });

  factory BatchIngestResultModel.fromJson(dynamic data) {
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    List<String> strings(String key) => (map[key] as List? ?? const []).map((e) => e.toString()).toList();
    final rejected = (map['rejected'] as List? ?? const [])
        .map((e) => e is Map ? (e['dedupe_hash'] ?? '').toString() : e.toString())
        .where((h) => h.isNotEmpty)
        .toList();
    final enrichments = (map['enrichments'] as List? ?? const []).whereType<Map>().map((e) {
      final slug = e['category'] as String?;
      return TransactionEnrichment(
        dedupeHash: e['dedupe_hash'].toString(),
        merchantName: e['merchant_name'] as String?,
        category: slug == null ? null : SpendCategory.fromSlug(slug),
      );
    }).toList();
    return BatchIngestResultModel(
      accepted: strings('accepted'),
      duplicates: strings('duplicates'),
      rejected: rejected,
      enrichments: enrichments,
    );
  }

  /// All hashes the server acknowledged (safe to remove from the queue).
  Set<String> get acknowledged => {...accepted, ...duplicates, ...rejected};
}
