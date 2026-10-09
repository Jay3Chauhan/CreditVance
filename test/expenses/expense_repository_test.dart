import 'package:cardsage/core/network/api_result.dart';
import 'package:cardsage/core/storage/local_cache_service.dart';
import 'package:cardsage/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:cardsage/features/expenses/data/models/batch_ingest_result_model.dart';
import 'package:cardsage/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:cardsage/features/expenses/domain/entities/card_transaction.dart';
import 'package:cardsage/features/expenses/domain/entities/sms_parse_result.dart';
import 'package:cardsage/features/expenses/domain/entities/sms_tracking_status.dart';
import 'package:cardsage/features/expenses/domain/entities/spend_category.dart';
import 'package:cardsage/features/expenses/domain/entities/tracked_card_ref.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalCacheService cache;
  late FakeSmsPlatform platform;
  late FakeExpenseRemote remote;
  late ExpenseRepositoryImpl repo;
  final now = DateTime.now();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = LocalCacheService(await SharedPreferences.getInstance());
    platform = FakeSmsPlatform(sampleInbox(now));
    remote = FakeExpenseRemote(cache);
    repo = ExpenseRepositoryImpl(platform: platform, local: ExpenseLocalDataSource(cache), remote: remote);
  });

  Future<void> grant() => repo.saveConsent(SmsConsent(status: SmsConsentStatus.granted, decidedAt: now));

  test('does not read SMS without consent', () async {
    final report = (await repo.scanInbox()).dataOrNull!;
    expect(report.scanned, 0);
    expect(await repo.getCachedTransactions(), isEmpty);
  });

  test('scan imports card spends + bill, filters noise, and never duplicates on rescan', () async {
    await grant();
    final report = (await repo.scanInbox()).dataOrNull!;
    expect(report.newTransactions, 4); // 3 spends + 1 refund
    expect(report.newBills, 1);
    expect(report.rejected[SmsRejectReason.otp], 1);
    expect(report.rejected[SmsRejectReason.notCreditCard], 1);
    // Promo (-P) and the unknown sender are dropped natively or by the parser.
    expect(report.scanned, 8);

    final again = (await repo.scanInbox(fullRescan: true)).dataOrNull!;
    expect(again.newTransactions, 0);
    expect(again.newBills, 0);
    expect((await repo.getCachedTransactions()).length, 4);
    expect(repo.pendingSyncCount, 5);
  });

  test('cached data is never written with raw SMS bodies', () async {
    await grant();
    await repo.scanInbox();
    final stored = cache.getExpenseTransactions()!;
    expect(stored.contains('Not You?'), isFalse);
    expect(stored.contains('OTP'), isFalse);
    expect(stored.contains('Avl Limit'), isFalse);
  });

  test('matches transactions to wallet cards by last 4 digits', () async {
    await grant();
    await repo.relinkCards(const [
      TrackedCardRef(userCardId: 101, last4: '9012', label: 'Primary Infinia', bankName: 'HDFC Bank'),
    ]);
    await repo.scanInbox();
    final hdfc = (await repo.getCachedTransactions()).firstWhere((t) => t.bankCode == 'HDFC');
    expect(hdfc.userCardId, 101);
  });

  test('offline and 404 keep the queue; success acknowledges and applies enrichment', () async {
    await grant();
    await repo.scanInbox();

    remote.online = false;
    var report = (await repo.syncPending()).dataOrNull!;
    expect(report.status, ExpenseSyncStatus.offline);
    expect(repo.pendingSyncCount, 5);

    remote.online = true;
    report = (await repo.syncPending()).dataOrNull!;
    expect(report.status, ExpenseSyncStatus.unavailable);
    expect(repo.pendingSyncCount, 5);

    remote.onUpload = (txns, bills) {
      final first = txns.first;
      return ApiSuccess(BatchIngestResultModel(
        accepted: [...txns.map((t) => t.id), ...bills.map((b) => b.id)],
        duplicates: const [],
        rejected: const [],
        enrichments: [
          TransactionEnrichment(dedupeHash: first.id, merchantName: 'Enriched Name', category: SpendCategory.travel),
        ],
      ));
    };
    report = (await repo.syncPending()).dataOrNull!;
    expect(report.status, ExpenseSyncStatus.synced);
    expect(repo.pendingSyncCount, 0);
    final txns = await repo.getCachedTransactions();
    expect(txns.every((t) => t.isSynced), isTrue);
    expect(txns.any((t) => t.merchantName == 'Enriched Name'), isTrue);

    final payload = remote.uploads.last.first.toSyncJson();
    expect(payload.containsKey('body'), isFalse);
    expect(payload['card_last4'].toString().length, 4);
  });

  test('excluded records are deleted remotely and never re-imported', () async {
    await grant();
    await repo.scanInbox();
    remote.onUpload = (txns, bills) => ApiSuccess(BatchIngestResultModel(
          accepted: [...txns.map((t) => t.id), ...bills.map((b) => b.id)],
          duplicates: const [],
          rejected: const [],
          enrichments: const [],
        ));
    await repo.syncPending();

    final victim = (await repo.getCachedTransactions()).first;
    await repo.excludeTransaction(victim.id);
    await repo.syncPending();
    expect(remote.deleted, [victim.id]);

    await repo.scanInbox(fullRescan: true);
    expect((await repo.getCachedTransactions()).any((t) => t.id == victim.id), isFalse);
  });

  test('pasted SMS is saved once; pasting it again is refused', () async {
    final y = now.subtract(const Duration(days: 1));
    String two(int v) => v.toString().padLeft(2, '0');
    final sms = 'Spent Rs.399.00 On HDFC Bank Card 1234 At UBER On '
        '${y.year}-${two(y.month)}-${two(y.day)}:22:10:01.Not You? Call 18002586161';

    expect(repo.previewPastedSms(sms), isA<ParsedTransaction>());
    expect((await repo.getCachedTransactions()), isEmpty); // preview never persists

    final first = await repo.importPastedSms(sms);
    expect(first.dataOrNull, isA<ParsedTransaction>());
    final t = (await repo.getCachedTransactions()).single;
    expect(t.source, TransactionSource.pastedSms);
    expect(t.merchantName, 'Uber');

    final second = await repo.importPastedSms(sms);
    expect(second.isFailure, isTrue);
    expect((await repo.getCachedTransactions()).length, 1);
  });

  test('manual transaction is stored with full confidence', () async {
    final result = await repo.addManualTransaction(
      amount: 250,
      merchant: 'Chai Point',
      category: SpendCategory.dining,
      type: TransactionType.debit,
      occurredAt: now,
    );
    expect(result.isSuccess, isTrue);
    final t = (await repo.getCachedTransactions()).single;
    expect(t.source, TransactionSource.manual);
    expect(t.confidence, 1.0);
    expect(repo.pendingSyncCount, 1);
  });

  test('delete all data wipes local state, withdraws consent and retries remote erase later', () async {
    await grant();
    await repo.scanInbox();
    remote.eraseSucceeds = false;
    await repo.deleteAllData();

    expect(await repo.getCachedTransactions(), isEmpty);
    expect(await repo.getCachedBills(), isEmpty);
    expect(repo.getConsent().status, SmsConsentStatus.withdrawn);
    expect(cache.getExpensePendingErase(), isTrue);

    remote.eraseSucceeds = true;
    await repo.syncPending();
    expect(cache.getExpensePendingErase(), isFalse);
    expect(remote.eraseCalls, 2);

    // Withdrawn consent stops scanning.
    expect((await repo.scanInbox()).dataOrNull!.scanned, 0);
  });
}
