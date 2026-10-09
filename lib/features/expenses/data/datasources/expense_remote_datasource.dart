import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_result.dart';
import '../../domain/entities/card_milestone.dart';
import '../../domain/entities/sms_tracking_status.dart';
import '../models/batch_ingest_result_model.dart';
import '../models/bill_notice_model.dart';
import '../models/card_milestone_model.dart';
import '../models/card_transaction_model.dart';
import '../models/sms_consent_model.dart';

/// Backend calls for SMS expense tracking. See `docs/sms_expense_tracking.md`
/// for the full API contract.
class ExpenseRemoteDataSource {
  final ApiClient _apiClient;

  ExpenseRemoteDataSource(this._apiClient);

  static const String clientVersion = '1.0.0';

  /// Whether the device currently has connectivity.
  Future<bool> get isOnline => _apiClient.networkInfo.isConnected;

  /// Uploads one batch. The `Idempotency-Key` is derived from the sorted hashes,
  /// so a retried batch is recognised by the server and not double-counted.
  Future<ApiResult<BatchIngestResultModel>> uploadBatch({
    required List<CardTransactionModel> transactions,
    required List<BillNoticeModel> bills,
  }) {
    final hashes = [...transactions.map((t) => t.id), ...bills.map((b) => b.id)]..sort();
    final idempotencyKey = sha256.convert(utf8.encode(hashes.join(','))).toString();
    return _apiClient.post<BatchIngestResultModel>(
      path: ApiEndpoints.expenseTransactionsBatch,
      headers: {'Idempotency-Key': idempotencyKey},
      data: {
        'client_version': clientVersion,
        'schema_version': 1,
        'transactions': [for (final t in transactions) t.toSyncJson()],
        'bills': [for (final b in bills) b.toSyncJson()],
      },
      fromJson: BatchIngestResultModel.fromJson,
    );
  }

  /// Deletes one record server-side (user marked it "not a transaction").
  Future<ApiResult<bool>> deleteTransaction(String dedupeHash) {
    return _apiClient.delete<bool>(
      path: ApiEndpoints.expenseTransactionByHash(dedupeHash),
      fromJson: (_) => true,
    );
  }

  /// Erases every SMS-derived record for the account (DPDP right to erasure).
  Future<ApiResult<bool>> deleteAllData() {
    return _apiClient.delete<bool>(path: ApiEndpoints.expenseData, fromJson: (_) => true);
  }

  /// Records the consent artefact (purpose, notice version, timestamp).
  Future<ApiResult<bool>> recordConsent(SmsConsent consent) {
    return _apiClient.put<bool>(
      path: ApiEndpoints.expenseConsent,
      data: SmsConsentModel.fromEntity(consent).toSyncJson(),
      fromJson: (_) => true,
    );
  }

  /// Milestone definitions for the user's saved cards.
  Future<ApiResult<List<CardMilestone>>> fetchMilestones() {
    return _apiClient.get<List<CardMilestone>>(
      path: ApiEndpoints.expenseMilestones,
      fromJson: (data) {
        final list = data is List ? data : (data is Map ? data['items'] as List? ?? const [] : const []);
        return list.map((e) => CardMilestoneModel.fromJson(e as Map<String, dynamic>)).toList();
      },
    );
  }
}
