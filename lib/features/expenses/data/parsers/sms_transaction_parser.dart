import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/entities/bill_notice.dart';
import '../../domain/entities/card_transaction.dart';
import '../../domain/entities/raw_sms.dart';
import '../../domain/entities/sms_parse_result.dart';
import '../../domain/entities/spend_category.dart';
import 'bank_sender_registry.dart';
import 'merchant_categorizer.dart';

class _ParsedDate {
  final DateTime value;
  final bool hasTime;
  const _ParsedDate(this.value, this.hasTime);
}

class _AmountMatch {
  final double value;
  final String currency;
  const _AmountMatch(this.value, this.currency);
}

/// On-device, regex-based parser that turns Indian bank credit card alert SMS
/// into structured [CardTransaction]s or [BillNotice]s.
///
/// Pipeline: sender gate → hard negative filters (OTP, declined, e-mandate
/// notices) → bill/statement detection → promo filter → instrument check
/// (credit card only) → field extraction → confidence scoring.
///
/// Pure Dart and side-effect free so it can run inside `Isolate.run` and is
/// fully unit-testable. Raw bodies are never retained.
class SmsTransactionParser {
  final BankSenderRegistry registry;
  final MerchantCategorizer categorizer;

  SmsTransactionParser({BankSenderRegistry? registry, MerchantCategorizer? categorizer})
      : registry = registry ?? const BankSenderRegistry(),
        categorizer = categorizer ?? MerchantCategorizer();

  /// Minimum confidence for an SMS to be accepted as a transaction.
  static const double acceptThreshold = 0.6;

  static RegExp _ci(String pattern) => RegExp(pattern, caseSensitive: false);

  static final RegExp _whitespace = RegExp(r'\s+');

  // ---- Hard negative filters ----
  static final List<RegExp> _otpRes = [
    _ci(r'\b\d{4,8}\b\s*(?:is\s+)?(?:your\s+|the\s+)?(?:otp|one[\s-]?time[\s-]?password|verification\s+code)\b'),
    _ci(r'\b(?:otp|one[\s-]?time[\s-]?password|verification\s+code)\s*(?:is|:|-|=)\s*\d{4,8}\b'),
    _ci(r'\b(?:otp|one[\s-]?time[\s-]?password)\s+for\b.{0,100}?\bis\s+\d{4,8}\b'),
  ];
  static final RegExp _declinedRe = _ci(
    r'\b(?:declined|unsuccessful|not\s+successful|failed|could\s+not\s+be\s+(?:processed|completed)|rejected|was\s+not\s+approved)\b',
  );
  static final RegExp _mandateRe = _ci(
    r'\b(?:e-?mandate|mandate|standing\s+instruction|auto[\s-]?pay|auto[\s-]?debit|pre-?debit|recurring\s+payment|si)\b',
  );
  static final RegExp _futureRe = _ci(
    r'\b(?:will\s+be|would\s+be|scheduled|upcoming|registered|set\s*up|created|to\s+be\s+(?:debited|charged)|pre-?debit|will\s+get|cancel(?:led)?|revoked|paused|modified)\b',
  );
  static final RegExp _completedRe = _ci(
    r'\b(?:has\s+been|have\s+been|was|is)\s+(?:debited|charged|deducted|processed|used)\b|\bspent\b',
  );
  static final RegExp _promoRe = _ci(
    r'\b(?:pre[\s-]?approved|apply\s+now|apply\s+here|limited\s+period|exclusive\s+offer|congratulations|you\s+are\s+eligible|get\s+up\s*to|win|lucky|hurry|avail\s+now|instant\s+loan|personal\s+loan|loan\s+of|offer\s+valid|use\s+code)\b',
  );

  // ---- Bill / statement ----
  static final RegExp _billKeywordRe = _ci(
    r'\b(?:statement|total\s+(?:amount|amt)\s+due|total\s+due|min(?:imum)?\.?\s+(?:amount|amt)\s+due|min\.?\s+due|payment\s+due|due\s+date|is\s+due|due\s+on|due\s+by|pay\s+by|tad|mad)\b',
  );
  static final RegExp _paymentReceivedRe = _ci(
    r'\bpayment\b.{0,60}\b(?:received|credited|posted)\b|\breceived\b.{0,40}\bpayment\b|thank\s+you\s+for\s+(?:your\s+|the\s+)?payment',
  );
  static final RegExp _totalDueRe = _ci(
    r'\b(?:total\s+(?:amount|amt)\s+due|total\s+due|tad|total\s+outstanding|payment\s+of|amount\s+due)\s*(?:is|:|-|of)?\s*(?:INR|Rs\.?|₹)\s*\.?\s*(\d[\d,]*(?:\.\d{1,2})?)',
  );
  static final RegExp _minDueRe = _ci(
    r'\b(?:min(?:imum)?\.?\s+(?:amount|amt)\s+due|min\.?\s+due|minimum\s+due|mad)\s*(?:is|:|-|of)?\s*(?:INR|Rs\.?|₹)\s*\.?\s*(\d[\d,]*(?:\.\d{1,2})?)',
  );
  static final RegExp _dueKeywordRe = _ci(
    r'\b(?:due\s+date|due\s+on|due\s+by|pay\s+by|payable\s+by|is\s+due)\b\s*[:\-]?\s*(?:on\s+)?',
  );

  // ---- Instrument ----
  static final RegExp _debitCardRe = _ci(r'\bdebit\s+card\b|\bblock\s+dc\b');
  static final RegExp _accountRe = _ci(r'\b(?:a/c|acct|account|ac\s+no|savings)\b');
  static final RegExp _cardMentionRe = _ci(r'\b(?:card|cc|creditcard)\b');

  // ---- Type ----
  static final RegExp _refundRe = _ci(r'\brefund(?:ed)?\b');
  static final RegExp _reversalRe = _ci(r'\brevers(?:al|ed)\b');
  static final RegExp _strongDebitRe = _ci(
    r'\b(?:spent|debited|charged|levied|used\s+for|purchase|deducted|withdrawn|has\s+been\s+used)\b',
  );
  static final RegExp _creditRe = _ci(r'\bcredited\b');
  static final RegExp _weakDebitRe = _ci(r'\b(?:transaction\s+of|txn\s+of|trxn\s+of|paid|payment\s+of)\b');
  static final RegExp _upiRe = _ci(r'\b(?:upi|vpa)\b');

  // ---- Fields ----
  static final RegExp _amountRe = _ci(
    r'(INR|Rs\.?|₹|USD|EUR|GBP|AED|SGD|AUD|CAD|JPY|CHF|THB|MYR)\s*\.?\s*(\d[\d,]*(?:\.\d{1,2})?)',
  );
  static final RegExp _amountContextExclusion = RegExp(
    r'\b(?:avl|avbl|available|limit|lmt|bal|balance|outstanding|due|minimum|min)\b',
  );
  static final List<RegExp> _last4Res = [
    _ci(r'\bending(?:\s+(?:with|in))?\s*[:\-]?\s*(?:[x*•#]+\s*)?(\d{4,5})\b'),
    _ci(r'\b(?:card|cc|a/c|acct)\s*(?:no\.?|number|num)?\s*[:\-]?\s*[x*•#]+\s*(\d{4,5})\b'),
    _ci(r'(?:^|\s)[x*•#]{2,}\s*(\d{4,5})\b'),
    _ci(r'\bcard\s+(\d{4})\b'),
  ];
  static final RegExp _availableLimitRe = _ci(
    r'\b(?:avl|avbl|available)\.?\s*(?:cr(?:edit)?\.?\s*)?(?:lmt|limit|bal|balance)\s*(?:is|:|-|of)?\s*(?:INR|Rs\.?|₹)\s*\.?\s*(\d[\d,]*(?:\.\d{1,2})?)',
  );
  static final RegExp _refRe = _ci(
    r'\b(?:upi\s*ref(?:\s*no)?|ref(?:erence)?\s*(?:no|number|id)?|rrn|txn\s*(?:id|no))\.?\s*[:\-]?\s*(?:is\s+)?([a-z0-9]{8,})\b',
  );

  static const String _stop =
      r'\s+on\s|\s+on$|\s+dated\b|\s+via\b|\s+for\s|\.\s|\.$|\s+avl\b|\s+avbl\b|\s+available\b|\s+ref\b|\s+txn\b|\s+using\b|,|\s+not\s+you|\s+if\s|\s+credited\b|\s+has\s|\s+is\s|\s+was\s|\s+to\s+your\b|\s*$';
  static final RegExp _merchantAtRe = _ci('\\bat\\s+(.+?)(?=$_stop)');
  static final RegExp _merchantInfoRe = _ci(
    r'\b(?:info|merchant(?:\s+name)?)\s*[:\-]\s*(.+?)(?=\.\s|\.$|\s+avl\b|\s+available\b|,|\s*$)',
  );
  static final RegExp _merchantAfterTimeRe = _ci(
    r'\d{1,2}:\d{2}(?::\d{2})?\s*(?:IST|AM|PM|hrs)?\s+(.+?)\s+(?=avl\b|avbl\b|available\b)',
  );
  static final RegExp _merchantAfterDateRe = _ci(
    r'\bon\s+\d{1,2}[-/ ](?:\d{1,2}|[a-z]{3,4})[-/ ]\d{2,4}\s+(?:on|at)\s+(.+?)(?=\.\s|\.$|\s+avl\b|\s+available\b|,|\s*$)',
  );
  static final RegExp _merchantTowardsRe = _ci(
    r'\btowards\s+(.+?)(?=\s+on\s|\s+via\b|\s+using\b|\.\s|\.$|\s+ref\b|,|\s*$)',
  );
  static final RegExp _merchantUpiRe = _ci(
    r'\bto\s+(?:vpa\s+)?([a-z0-9._\-]+@[a-z0-9]+)(?:\s+([a-z][a-z0-9 &.\-]{1,40}?))?(?=\s+on\s|\s+ref\b|\.\s|\.$|\s*\(|\s+upi\b|,|\s*$)',
  );
  static final RegExp _merchantFromRe = _ci(
    r'\bfrom\s+(.+?)(?=\s+has\s|\s+is\s|\s+on\s|\s+credited|\s+to\s|\s+for\s|\.\s|\.$|,|\s*$)',
  );
  static final RegExp _merchantForRe = _ci(
    r'\bfor\s+(?!a\b|the\b|your\b|txn\b|transaction\b|rs\b|inr\b)(.+?)(?=\s+on\s|\s+via\b|\.\s|\.$|,|\s*$)',
  );

  static final List<MapEntry<RegExp, String>> _feeLabels = [
    MapEntry(_ci(r'\b(?:annual|renewal)\s+(?:membership\s+)?fee'), 'Annual Fee'),
    MapEntry(_ci(r'\bjoining\s+fee'), 'Joining Fee'),
    MapEntry(_ci(r'\blate\s+payment\s+(?:fee|charge)'), 'Late Payment Fee'),
    MapEntry(_ci(r'\bfinance\s+charges?|\binterest\s+(?:charge|amount)|\binterest\s+of\b'), 'Finance Charges'),
    MapEntry(_ci(r'\bover\s*-?\s*limit\s+(?:fee|charge)'), 'Over-limit Fee'),
    MapEntry(_ci(r'\bcash\s+(?:advance|withdrawal)\s+(?:fee|charge)'), 'Cash Advance Fee'),
    MapEntry(_ci(r'\b(?:forex|cross[\s-]currency|foreign\s+currency)\s+(?:markup|mark-up|transaction)\s*(?:fee|charge)?'),
        'Forex Markup Fee'),
  ];

  // ---- Dates ----
  static final RegExp _isoDateRe = RegExp(
    r'\b(20\d{2})-(\d{2})-(\d{2})(?:[:\sT]+(\d{2}):(\d{2})(?::(\d{2}))?)?',
  );
  static final RegExp _monthNameDateRe = _ci(
    r"\b(\d{1,2})(?:st|nd|rd|th)?[-\s/]?(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?(?:[-\s/,']*(\d{4}|\d{2})\b)?",
  );
  static final RegExp _numericDateRe = RegExp(r'\b(\d{1,2})[-/.](\d{1,2})[-/.](\d{4}|\d{2})\b');
  static final RegExp _timeRe = _ci(r'\b(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)?');
  static const List<String> _months = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  static final Set<String> _merchantStopWords = {
    'your', 'you', 'card', 'credit card', 'rs', 'inr', 'a', 'the', 'bank', 'ist', 'am', 'pm',
  };

  /// Parses one SMS. Never throws; malformed input yields a [RejectedSms].
  SmsParseOutcome parse(RawSms sms) {
    try {
      return _parse(sms);
    } catch (_) {
      return const RejectedSms(SmsRejectReason.informational);
    }
  }

  /// Parses a batch of SMS (safe to call inside `Isolate.run`).
  List<SmsParseOutcome> parseAll(List<RawSms> messages) => [for (final m in messages) parse(m)];

  SmsParseOutcome _parse(RawSms sms) {
    final text = sms.body.replaceAll(_whitespace, ' ').trim();
    if (text.isEmpty) return const RejectedSms(SmsRejectReason.informational);
    final lower = text.toLowerCase();
    final sender = SenderId.parse(sms.sender);
    final isInbox = sms.origin == SmsOrigin.inbox;

    // 1. Sender gate (anti-spoofing: bank alerts never come from phone numbers).
    if (isInbox && sender.isPhoneNumber) return const RejectedSms(SmsRejectReason.personalNumber);
    if (sender.category == SenderCategory.promotional) return const RejectedSms(SmsRejectReason.promotional);

    var bank = registry.resolveSender(sender);
    final bankFromSender = bank != null;
    bank ??= registry.inferFromBody(lower);
    if (isInbox && !bankFromSender && !(sender.isTransactionalOrService && bank != null)) {
      return const RejectedSms(SmsRejectReason.unknownSender);
    }

    // 2. Hard negative filters.
    if (_otpRes.any((re) => re.hasMatch(lower))) return const RejectedSms(SmsRejectReason.otp);

    final isRefund = _refundRe.hasMatch(lower);
    final isReversal = _reversalRe.hasMatch(lower);
    if (!isRefund && !isReversal && _declinedRe.hasMatch(lower)) {
      return const RejectedSms(SmsRejectReason.declined);
    }
    if (_mandateRe.hasMatch(lower) && _futureRe.hasMatch(lower) && !_completedRe.hasMatch(lower)) {
      return const RejectedSms(SmsRejectReason.mandateNotice);
    }

    // 3. Strongly promotional content (multiple marketing signals).
    final promoHits = _promoRe.allMatches(lower).length;
    if (promoHits >= 2) return const RejectedSms(SmsRejectReason.promotional);

    // 4. Statement / bill-due notices.
    final isPaymentReceived = _paymentReceivedRe.hasMatch(lower);
    final hasStrongDebit = _strongDebitRe.hasMatch(lower);
    if (!isPaymentReceived && !hasStrongDebit && !isRefund && _billKeywordRe.hasMatch(lower)) {
      final bill = _parseBill(text, bank ?? BankSenderRegistry.unknownBank, sms.receivedAt);
      return bill == null ? const RejectedSms(SmsRejectReason.informational) : ParsedBillNotice(bill);
    }

    // 4b. Single promo signal without solid transaction evidence.
    final last4 = _extractLast4(text);
    final strongTxnEvidence = hasStrongDebit && last4 != null;
    if (promoHits == 1 && !strongTxnEvidence) return const RejectedSms(SmsRejectReason.promotional);

    // 5. Instrument: credit cards only.
    if (_debitCardRe.hasMatch(lower)) return const RejectedSms(SmsRejectReason.notCreditCard);
    final hasCardMention = _cardMentionRe.hasMatch(lower);
    if (!hasCardMention && _accountRe.hasMatch(lower)) return const RejectedSms(SmsRejectReason.notCreditCard);

    // 6. Field extraction.
    final type = _detectType(lower, isRefund, isReversal, isPaymentReceived, hasStrongDebit);
    if (type == null) return const RejectedSms(SmsRejectReason.informational);

    final amount = _extractAmount(text);
    if (amount == null || amount.value <= 0) return const RejectedSms(SmsRejectReason.noAmount);
    if (!hasCardMention && last4 == null) return const RejectedSms(SmsRejectReason.notCreditCard);

    final channel = _upiRe.hasMatch(lower) ? TransactionChannel.upi : TransactionChannel.card;
    final feeLabel = type == TransactionType.debit ? _detectFee(lower) : null;
    final merchantRaw = feeLabel ?? _extractMerchant(text, type);
    final parsedDate = _extractDate(text, sms.receivedAt);
    final availableLimit = _labelledAmount(_availableLimitRe, text);
    final ref = _extractRef(text);

    // 7. Confidence scoring.
    var confidence = 0.0;
    if (bankFromSender) {
      confidence += 0.30;
    } else if (bank != null) {
      confidence += 0.15;
    }
    confidence += 0.25; // amount present
    if (hasStrongDebit || isRefund || isReversal || isPaymentReceived) confidence += 0.15;
    if (last4 != null) confidence += 0.15;
    if (merchantRaw != null || type == TransactionType.payment) confidence += 0.10;
    if (parsedDate != null) confidence += 0.05;
    if (sender.isTransactionalOrService) confidence += 0.05;
    if (lower.contains('credit card')) confidence += 0.05;
    confidence = confidence.clamp(0.0, 1.0);
    if (confidence < acceptThreshold) return const RejectedSms(SmsRejectReason.lowConfidence);

    // 8. Normalisation.
    final resolvedBank = bank ?? BankSenderRegistry.unknownBank;
    final String merchantName;
    final SpendCategory category;
    if (feeLabel != null) {
      merchantName = feeLabel;
      category = SpendCategory.fees;
    } else if (type == TransactionType.payment) {
      merchantName = 'Card Bill Payment';
      category = SpendCategory.other;
    } else if (merchantRaw == null) {
      merchantName = type == TransactionType.credit ? 'Card Credit' : 'Unknown Merchant';
      category = SpendCategory.other;
    } else {
      final info = categorizer.categorize(merchantRaw);
      merchantName = info.name;
      category = info.category;
    }

    final occurredAt = _resolveOccurredAt(parsedDate, sms.receivedAt);
    final String timeKey;
    if (ref != null) {
      timeKey = 'ref:${ref.toUpperCase()}';
    } else if (parsedDate != null && parsedDate.hasTime) {
      timeKey = 'at:${_minuteKey(parsedDate.value)}';
    } else if (isInbox) {
      timeKey = 'rx:${sms.receivedAt.millisecondsSinceEpoch ~/ 1000}';
    } else {
      timeKey = 'day:${_dayKey(occurredAt)}|${MerchantCategorizer.compactKey(merchantRaw ?? '')}';
    }
    final id = dedupeHash(
      '${resolvedBank.code}|${last4 ?? '-'}|${type.name}|${(amount.value * 100).round()}|${amount.currency}|$timeKey',
    );

    return ParsedTransaction(
      CardTransaction(
        id: id,
        amount: amount.value,
        currency: amount.currency,
        type: type,
        occurredAt: occurredAt,
        bankCode: resolvedBank.code,
        bankName: resolvedBank.displayName,
        cardLast4: last4,
        merchantRaw: merchantRaw ?? '',
        merchantName: merchantName,
        category: category,
        channel: channel,
        availableLimit: availableLimit,
        source: isInbox ? TransactionSource.sms : TransactionSource.pastedSms,
        confidence: double.parse(confidence.toStringAsFixed(2)),
      ),
    );
  }

  /// Stable 128-bit (32 hex chars) SHA-256 prefix used as the dedupe key.
  static String dedupeHash(String key) => sha256.convert(utf8.encode(key)).toString().substring(0, 32);

  TransactionType? _detectType(
    String lower,
    bool isRefund,
    bool isReversal,
    bool isPaymentReceived,
    bool hasStrongDebit,
  ) {
    if (isRefund) return TransactionType.refund;
    if (isReversal) return TransactionType.reversal;
    if (isPaymentReceived) return TransactionType.payment;
    if (hasStrongDebit) return TransactionType.debit;
    if (_creditRe.hasMatch(lower)) return TransactionType.credit;
    if (_weakDebitRe.hasMatch(lower)) return TransactionType.debit;
    return null;
  }

  _AmountMatch? _extractAmount(String text) {
    var previousEnd = 0;
    for (final m in _amountRe.allMatches(text)) {
      final windowStart = (m.start - 22).clamp(previousEnd, m.start);
      final context = text.substring(windowStart, m.start).toLowerCase();
      previousEnd = m.end;
      if (_amountContextExclusion.hasMatch(context)) continue;
      final value = _parseNumber(m.group(2));
      if (value == null) continue;
      return _AmountMatch(value, _currencyCode(m.group(1)!));
    }
    return null;
  }

  static String _currencyCode(String token) {
    final t = token.toUpperCase().replaceAll('.', '');
    if (t == 'RS' || t == '₹' || t == 'INR') return 'INR';
    return t;
  }

  static double? _parseNumber(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.replaceAll(',', '');
    return double.tryParse(cleaned);
  }

  double? _labelledAmount(RegExp re, String text) => _parseNumber(re.firstMatch(text)?.group(1));

  /// Last 4 digits of the masked card number (AMEX alerts show 5; only 4 are kept).
  String? _extractLast4(String text) {
    for (final re in _last4Res) {
      final digits = re.firstMatch(text)?.group(1);
      if (digits != null) return digits.substring(digits.length - 4);
    }
    return null;
  }

  String? _extractRef(String text) {
    final m = _refRe.firstMatch(text);
    final ref = m?.group(1);
    if (ref == null || !ref.contains(RegExp(r'\d'))) return null;
    return ref;
  }

  String? _detectFee(String lower) {
    for (final entry in _feeLabels) {
      if (entry.key.hasMatch(lower)) return entry.value;
    }
    return null;
  }

  String? _extractMerchant(String text, TransactionType type) {
    if (type == TransactionType.payment) return null;

    final upi = _merchantUpiRe.firstMatch(text);
    if (upi != null) {
      final name = _cleanMerchant(upi.group(2));
      return name ?? upi.group(1)!.toLowerCase();
    }

    final candidates = <RegExp>[
      _merchantAtRe,
      _merchantInfoRe,
      _merchantAfterDateRe,
      _merchantAfterTimeRe,
      _merchantTowardsRe,
      if (type != TransactionType.debit) _merchantFromRe,
      _merchantForRe,
    ];
    for (final re in candidates) {
      for (final m in re.allMatches(text)) {
        final cleaned = _cleanMerchant(m.group(1));
        if (cleaned != null) return cleaned;
      }
    }
    return null;
  }

  String? _cleanMerchant(String? raw) {
    if (raw == null) return null;
    var s = raw.trim().replaceAll(RegExp(r'[\s.,;:\-]+$'), '').replaceFirst(_ci(r'^the\s+'), '').trim();
    if (s.length < 2 || !s.contains(RegExp(r'[A-Za-z]'))) return null;
    final lower = s.toLowerCase();
    if (_merchantStopWords.contains(lower)) return null;
    if (lower.startsWith('your ') || lower.contains('credit card') || lower.contains('bank card')) return null;
    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(s)) return null;
    if (_numericDateRe.hasMatch(s) && s.length <= 10) return null;
    if (RegExp(r'^(?:inr|rs\.?|₹)\s*\d', caseSensitive: false).hasMatch(s)) return null;
    if (s.length > 48) s = s.substring(0, 48).trim();
    return s;
  }

  _ParsedDate? _extractDate(
    String text,
    DateTime reference, {
    Duration back = const Duration(days: 60),
    Duration ahead = const Duration(days: 2),
  }) {
    DateTime? date;
    var hasTime = false;
    var matchEnd = 0;

    final iso = _isoDateRe.firstMatch(text);
    if (iso != null) {
      final h = int.tryParse(iso.group(4) ?? '');
      final mi = int.tryParse(iso.group(5) ?? '');
      final s = int.tryParse(iso.group(6) ?? '') ?? 0;
      date = _safeDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!), int.parse(iso.group(3)!),
          h ?? 0, mi ?? 0, s);
      hasTime = h != null && mi != null;
      matchEnd = iso.end;
    }

    if (date == null) {
      final mn = _monthNameDateRe.firstMatch(text);
      if (mn != null) {
        final month = _months.indexOf(mn.group(2)!.toLowerCase().substring(0, 3)) + 1;
        final yearRaw = mn.group(3);
        var year = yearRaw == null ? reference.year : _expandYear(int.parse(yearRaw));
        date = _safeDate(year, month, int.parse(mn.group(1)!));
        if (date != null && yearRaw == null && date.isAfter(reference.add(ahead))) {
          year -= 1;
          date = _safeDate(year, month, int.parse(mn.group(1)!));
        }
        matchEnd = mn.end;
      }
    }

    if (date == null) {
      final nd = _numericDateRe.firstMatch(text);
      if (nd != null) {
        date = _safeDate(
          _expandYear(int.parse(nd.group(3)!)),
          int.parse(nd.group(2)!),
          int.parse(nd.group(1)!),
        );
        matchEnd = nd.end;
      }
    }

    if (date == null) return null;

    if (!hasTime) {
      final t = _timeRe.firstMatch(text.substring(matchEnd));
      if (t != null) {
        var hour = int.parse(t.group(1)!);
        final minute = int.parse(t.group(2)!);
        final second = int.tryParse(t.group(3) ?? '') ?? 0;
        final meridiem = t.group(4)?.toLowerCase();
        if (meridiem == 'pm' && hour < 12) hour += 12;
        if (meridiem == 'am' && hour == 12) hour = 0;
        final withTime = _safeDate(date.year, date.month, date.day, hour, minute, second);
        if (withTime != null) {
          date = withTime;
          hasTime = true;
        }
      }
    }

    if (date.isBefore(reference.subtract(back)) || date.isAfter(reference.add(ahead))) return null;
    return _ParsedDate(date, hasTime);
  }

  static int _expandYear(int y) => y < 100 ? 2000 + y : y;

  static DateTime? _safeDate(int y, int m, int d, [int h = 0, int mi = 0, int s = 0]) {
    if (m < 1 || m > 12 || d < 1 || d > 31 || h > 23 || mi > 59 || s > 59) return null;
    final dt = DateTime(y, m, d, h, mi, s);
    if (dt.month != m || dt.day != d) return null;
    return dt;
  }

  static DateTime _resolveOccurredAt(_ParsedDate? parsed, DateTime receivedAt) {
    if (parsed == null) return receivedAt;
    if (parsed.hasTime) return parsed.value;
    final p = parsed.value;
    if (p.year == receivedAt.year && p.month == receivedAt.month && p.day == receivedAt.day) {
      return receivedAt;
    }
    return DateTime(p.year, p.month, p.day, 12);
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _dayKey(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  static String _minuteKey(DateTime d) => '${_dayKey(d)}T${_two(d.hour)}:${_two(d.minute)}';

  BillNotice? _parseBill(String text, BankProfile bank, DateTime receivedAt) {
    var total = _labelledAmount(_totalDueRe, text);
    final minimum = _labelledAmount(_minDueRe, text);

    DateTime? dueDate;
    final dueMatch = _dueKeywordRe.firstMatch(text);
    if (dueMatch != null) {
      dueDate = _extractDate(
        text.substring(dueMatch.end),
        receivedAt,
        back: const Duration(days: 10),
        ahead: const Duration(days: 75),
      )?.value;
    }

    if (total == null && minimum == null) {
      final fallback = _extractAmount(text);
      total = fallback?.value;
    }
    if (total == null && minimum == null && dueDate == null) return null;

    final last4 = _extractLast4(text);
    final dueKey = dueDate != null ? _dayKey(dueDate) : 'rx:${_dayKey(receivedAt)}';
    return BillNotice(
      id: dedupeHash('bill|${bank.code}|${last4 ?? '-'}|$dueKey'),
      bankCode: bank.code,
      bankName: bank.displayName,
      cardLast4: last4,
      totalDue: total,
      minimumDue: minimum,
      dueDate: dueDate == null ? null : DateTime(dueDate.year, dueDate.month, dueDate.day),
      noticedAt: receivedAt,
    );
  }
}
