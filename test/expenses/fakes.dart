import 'dart:async';

import 'package:credvert/core/network/api_client.dart';
import 'package:credvert/core/network/api_result.dart';
import 'package:credvert/core/storage/local_cache_service.dart';
import 'package:credvert/features/expenses/data/datasources/expense_remote_datasource.dart';
import 'package:credvert/features/expenses/data/datasources/sms_platform_datasource.dart';
import 'package:credvert/features/expenses/data/models/batch_ingest_result_model.dart';
import 'package:credvert/features/expenses/data/models/bill_notice_model.dart';
import 'package:credvert/features/expenses/data/models/card_transaction_model.dart';
import 'package:credvert/features/expenses/domain/entities/card_milestone.dart';
import 'package:credvert/features/expenses/domain/entities/raw_sms.dart';
import 'package:credvert/features/expenses/domain/entities/sms_tracking_status.dart';

/// In-memory Android SMS inbox.
class FakeSmsPlatform implements SmsPlatformDataSource {
  final List<RawSms> inbox;
  bool granted;
  bool supported;
  final StreamController<DateTime> incoming = StreamController<DateTime>.broadcast();

  FakeSmsPlatform(this.inbox, {this.granted = true, this.supported = true});

  @override
  bool get isSupported => supported;

  @override
  Future<NativeSmsPermission> checkPermission() async =>
      NativeSmsPermission(granted: granted, shouldShowRationale: !granted);

  @override
  Future<NativeSmsPermission> requestPermission() => checkPermission();

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<List<RawSms>> queryInbox({
    required DateTime since,
    required List<String> senderKeys,
    required int limit,
  }) async {
    final rows = inbox
        .where((m) => m.receivedAt.isAfter(since))
        .where((m) => senderKeys.any((k) => m.sender.toUpperCase().contains(k)))
        .toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));
    return rows.take(limit).toList();
  }

  @override
  Stream<DateTime> incomingBankSms(List<String> senderKeys) => incoming.stream;
}

/// Remote datasource with scripted responses and captured payloads.
class FakeExpenseRemote extends ExpenseRemoteDataSource {
  ApiResult<BatchIngestResultModel> Function(List<CardTransactionModel>, List<BillNoticeModel>) onUpload;
  bool online = true;
  bool eraseSucceeds = true;
  final List<List<CardTransactionModel>> uploads = [];
  final List<String> deleted = [];
  int eraseCalls = 0;
  int consentCalls = 0;

  FakeExpenseRemote(LocalCacheService cache)
      : onUpload = ((t, b) => const ApiFailure<BatchIngestResultModel>('Not found', statusCode: 404)),
        super(ApiClient(cacheService: cache));

  @override
  Future<bool> get isOnline async => online;

  @override
  Future<ApiResult<BatchIngestResultModel>> uploadBatch({
    required List<CardTransactionModel> transactions,
    required List<BillNoticeModel> bills,
  }) async {
    uploads.add(transactions);
    return onUpload(transactions, bills);
  }

  @override
  Future<ApiResult<bool>> deleteTransaction(String dedupeHash) async {
    deleted.add(dedupeHash);
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<bool>> deleteAllData() async {
    eraseCalls++;
    return eraseSucceeds ? const ApiSuccess(true) : const ApiFailure('offline');
  }

  @override
  Future<ApiResult<bool>> recordConsent(SmsConsent consent) async {
    consentCalls++;
    return const ApiFailure('Not found', statusCode: 404);
  }

  @override
  Future<ApiResult<List<CardMilestone>>> fetchMilestones() async =>
      const ApiFailure('Not found', statusCode: 404);
}

/// A realistic mixed inbox: spends, refund, payment, statement, OTP, promo, debit card.
List<RawSms> sampleInbox(DateTime now) {
  DateTime ago(int days, [int hour = 10]) =>
      DateTime(now.year, now.month, now.day, hour).subtract(Duration(days: days));
  return [
    RawSms(
      sender: 'AD-HDFCBK-T',
      body: 'Spent Rs.1,234.00 On HDFC Bank Card 9012 At AMAZON On ${_iso(ago(3))}.Not You? Call 18002586161',
      receivedAt: ago(3).add(const Duration(minutes: 1)),
    ),
    RawSms(
      sender: 'VM-ICICIT-T',
      body: 'INR 640.00 spent using ICICI Bank Card XX5678 on ${_dmy(ago(2))} on SWIGGY. Avl Limit: INR 50,000.00.',
      receivedAt: ago(2),
    ),
    RawSms(
      sender: 'JD-SBICRD-S',
      body: 'Rs.2,500.00 spent on your SBI Credit Card ending with 4321 at BIGBASKET on ${_dmy(ago(1))}.',
      receivedAt: ago(1),
    ),
    RawSms(
      sender: 'VM-ICICIT-T',
      body: 'Refund of INR 140.00 from SWIGGY has been credited to your ICICI Bank Credit Card XX5678.',
      receivedAt: ago(1, 15),
    ),
    RawSms(
      sender: 'AD-HDFCBK-S',
      body: 'Your HDFC Bank Credit Card ending 9012 statement has been generated. Total Amt Due: Rs.12,345.67, '
          'Min Amt Due: Rs.620.00, Payment Due Date: ${_dmy(now.add(const Duration(days: 10)))}.',
      receivedAt: ago(4),
    ),
    RawSms(
      sender: 'VM-ICICIT-T',
      body: '482913 is the OTP for transaction of INR 1,234.00 at AMAZON on your ICICI Bank Credit Card XX5678.',
      receivedAt: ago(5),
    ),
    RawSms(
      sender: 'VM-HDFCBK-P',
      body: 'Get a pre-approved Personal Loan of up to Rs.5,00,000. Apply now!',
      receivedAt: ago(6),
    ),
    RawSms(
      sender: 'AD-HDFCBK-T',
      body: 'Rs.500.00 spent on HDFC Bank Debit Card xx5678 at DMART on ${_dmy(ago(6))}.',
      receivedAt: ago(6, 11),
    ),
    RawSms(sender: 'VM-SWIGGY-S', body: 'Your order of Rs 450 is on the way!', receivedAt: ago(2, 20)),
  ];
}

String _two(int v) => v.toString().padLeft(2, '0');
String _iso(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}:${_two(d.hour)}:${_two(d.minute)}:00';
String _dmy(DateTime d) => '${_two(d.day)}-${_two(d.month)}-${d.year}';
