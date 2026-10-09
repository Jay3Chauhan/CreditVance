import 'package:credvert/features/expenses/data/parsers/bank_sender_registry.dart';
import 'package:credvert/features/expenses/data/parsers/merchant_categorizer.dart';
import 'package:credvert/features/expenses/data/parsers/sms_transaction_parser.dart';
import 'package:credvert/features/expenses/domain/entities/bill_notice.dart';
import 'package:credvert/features/expenses/domain/entities/card_transaction.dart';
import 'package:credvert/features/expenses/domain/entities/raw_sms.dart';
import 'package:credvert/features/expenses/domain/entities/sms_parse_result.dart';
import 'package:credvert/features/expenses/domain/entities/spend_category.dart';
import 'package:flutter_test/flutter_test.dart';

/// Realistic (anonymised) Indian bank credit card alert samples.
/// Card numbers, phone numbers and references are synthetic.
void main() {
  final parser = SmsTransactionParser();
  final receivedAt = DateTime(2025, 5, 1, 10, 15);

  SmsParseOutcome parse(String sender, String body, {DateTime? at, SmsOrigin origin = SmsOrigin.inbox}) {
    return parser.parse(RawSms(sender: sender, body: body, receivedAt: at ?? receivedAt, origin: origin));
  }

  CardTransaction expectTxn(SmsParseOutcome outcome) {
    expect(outcome, isA<ParsedTransaction>(), reason: 'Expected a transaction but got $outcome'
        '${outcome is RejectedSms ? ' (${outcome.reason})' : ''}');
    return (outcome as ParsedTransaction).transaction;
  }

  SmsRejectReason expectRejected(SmsParseOutcome outcome) {
    expect(outcome, isA<RejectedSms>(), reason: 'Expected rejection but got $outcome');
    return (outcome as RejectedSms).reason;
  }

  group('SenderId parsing (TRAI header formats)', () {
    test('legacy operator prefix format AD-HDFCBK', () {
      final s = SenderId.parse('AD-HDFCBK');
      expect(s.operatorPrefix, 'AD');
      expect(s.core, 'HDFCBK');
      expect(s.category, SenderCategory.unknown);
      expect(s.isPhoneNumber, isFalse);
    });

    test('new suffix format VM-ICICIT-T / JD-SBICRD-S / VM-HDFCBK-P', () {
      expect(SenderId.parse('VM-ICICIT-T').category, SenderCategory.transactional);
      expect(SenderId.parse('JD-SBICRD-S').category, SenderCategory.service);
      expect(SenderId.parse('VM-HDFCBK-P').category, SenderCategory.promotional);
      expect(SenderId.parse('AX-GOVIND-G').category, SenderCategory.government);
      expect(SenderId.parse('VM-ICICIT-T').core, 'ICICIT');
    });

    test('bare header and phone numbers', () {
      expect(SenderId.parse('AXISBK').core, 'AXISBK');
      expect(SenderId.parse('+919876543210').isPhoneNumber, isTrue);
      expect(SenderId.parse('09876543210').isPhoneNumber, isTrue);
    });

    test('registry resolves known issuers from header cores', () {
      const registry = BankSenderRegistry();
      expect(registry.resolveSender(SenderId.parse('AD-HDFCBK'))?.code, 'HDFC');
      expect(registry.resolveSender(SenderId.parse('VM-ICICIT-T'))?.code, 'ICICI');
      expect(registry.resolveSender(SenderId.parse('JD-SBICRD-S'))?.code, 'SBICARD');
      expect(registry.resolveSender(SenderId.parse('AD-AMEXIN'))?.code, 'AMEX');
      expect(registry.resolveSender(SenderId.parse('VM-SWIGGY-S')), isNull);
      expect(registry.resolveSender(SenderId.parse('+919876543210')), isNull);
    });
  });

  group('Positive: credit card spends across issuers', () {
    test('HDFC Bank — "Spent Rs. On HDFC Bank Card 1234 At ..."', () {
      final t = expectTxn(parse(
        'AD-HDFCBK-T',
        'Spent Rs.1,234.00 On HDFC Bank Card 1234 At AMAZON On 2025-05-01:10:12:13.Not You? '
            'To Block+Reissue Call 18002586161/SMS BLOCK CC 1234 to 7308080808',
      ));
      expect(t.amount, 1234.00);
      expect(t.currency, 'INR');
      expect(t.type, TransactionType.debit);
      expect(t.bankCode, 'HDFC');
      expect(t.cardLast4, '1234');
      expect(t.merchantName, 'Amazon');
      expect(t.category, SpendCategory.shopping);
      expect(t.occurredAt, DateTime(2025, 5, 1, 10, 12, 13));
      expect(t.confidence, greaterThanOrEqualTo(0.9));
      expect(t.needsReview, isFalse);
    });

    test('ICICI Bank — "INR spent using ICICI Bank Card XX1234 on <date> on <merchant>"', () {
      final t = expectTxn(parse(
        'VM-ICICIT-T',
        'INR 1,234.00 spent using ICICI Bank Card XX5678 on 01-May-25 on SWIGGY. Avl Limit: INR 1,23,456.78. '
            'If not you, call 1800 2662/SMS BLOCK 5678 to 9215676766.',
      ));
      expect(t.amount, 1234.00);
      expect(t.bankCode, 'ICICI');
      expect(t.cardLast4, '5678');
      expect(t.merchantName, 'Swiggy');
      expect(t.category, SpendCategory.dining);
      expect(t.availableLimit, 123456.78);
      expect(t.occurredAt, receivedAt); // same day, no time → SMS receipt time
    });

    test('SBI Card — "spent on your SBI Credit Card ending with 1234 at ..."', () {
      final t = expectTxn(parse(
        'JD-SBICRD-S',
        'Rs.2,500.00 spent on your SBI Credit Card ending with 4321 at BIGBASKET on 30/04/25. '
            'Trxn. not done by you? Report at https://sbicard.com/Dispute',
      ));
      expect(t.amount, 2500.00);
      expect(t.bankCode, 'SBICARD');
      expect(t.cardLast4, '4321');
      expect(t.merchantName, 'BigBasket');
      expect(t.category, SpendCategory.groceries);
      expect(t.occurredAt, DateTime(2025, 4, 30, 12));
    });

    test('Axis Bank — new multi-line format with merchant on its own line', () {
      final t = expectTxn(parse(
        'VM-AXISBK-T',
        'Spent\nCard no. XX7765\nINR 4599\n01-05-25 09:41:07 IST\nINDIGO AIRLINES\nAvl Lmt INR 245401.50\n'
            'SMS BLOCK 7765 to 919951860002, if not you - Axis Bank',
      ));
      expect(t.amount, 4599);
      expect(t.bankCode, 'AXIS');
      expect(t.cardLast4, '7765');
      expect(t.merchantName, 'IndiGo');
      expect(t.category, SpendCategory.travel);
      expect(t.availableLimit, 245401.50);
      expect(t.occurredAt, DateTime(2025, 5, 1, 9, 41, 7));
    });

    test('Kotak — "spent on Kotak Credit Card x1234 at ..."', () {
      final t = expectTxn(parse(
        'BP-KOTAKB',
        'Rs.850.00 spent on Kotak Credit Card x2468 at HPCL PETROL PUMP on 01/05/2025. '
            'Avl limit Rs.98,150.00. Not you? Call 18602662666',
      ));
      expect(t.bankCode, 'KOTAK');
      expect(t.cardLast4, '2468');
      expect(t.category, SpendCategory.fuel);
      expect(t.availableLimit, 98150.00);
    });

    test('American Express — 5-digit card suffix and 12h time', () {
      final t = expectTxn(parse(
        'AD-AMEXIN',
        "Alert: You've spent INR 3,210.00 on your AMEX card ** 41006 at TAJ HOTELS MUMBAI on 1 May 2025 at 01:23 PM IST. "
            'Call 18004190691 if this was not made by you.',
        at: DateTime(2025, 5, 1, 13, 30),
      ));
      expect(t.bankCode, 'AMEX');
      expect(t.cardLast4, '1006');
      expect(t.merchantName, 'Taj Hotels');
      expect(t.category, SpendCategory.travel);
      expect(t.occurredAt, DateTime(2025, 5, 1, 13, 23));
    });

    test('IDFC FIRST — "Transaction Successful!" prefix is not treated as a failure', () {
      final t = expectTxn(parse(
        'VM-IDFCFB-T',
        'Transaction Successful! INR 1,499.00 spent on your IDFC FIRST Bank Credit Card ending XX9911 at '
            'BOOKMYSHOW on 01 MAY 2025 at 10:05 AM. Avl Limit: INR 48,501.00. If not done by you, call 18002669970.',
      ));
      expect(t.bankCode, 'IDFC');
      expect(t.cardLast4, '9911');
      expect(t.category, SpendCategory.entertainment);
      expect(t.occurredAt, DateTime(2025, 5, 1, 10, 5));
    });

    test('AU Small Finance Bank', () {
      final t = expectTxn(parse(
        'AD-AUBANK-T',
        'Dear Customer, INR 640.00 has been spent on your AU Bank Credit Card XX3030 at APOLLO PHARMACY on '
            '01-05-2025 08:55:10. Available limit: INR 59,360.00. Not you? Call 1800 1200 1500',
      ));
      expect(t.bankCode, 'AU');
      expect(t.cardLast4, '3030');
      expect(t.category, SpendCategory.health);
      expect(t.availableLimit, 59360.00);
    });

    test('OneCard — ₹ symbol amounts', () {
      final t = expectTxn(parse(
        'VM-ONECRD-T',
        "You've spent ₹1,180.00 at ZOMATO on your OneCard credit card ending XX5050. Avl limit: ₹78,820.00",
      ));
      expect(t.bankCode, 'ONECARD');
      expect(t.amount, 1180.00);
      expect(t.merchantName, 'Zomato');
      expect(t.availableLimit, 78820.00);
    });

    test('RuPay credit card on UPI — VPA + merchant name, UPI channel', () {
      final t = expectTxn(parse(
        'AD-HDFCBK-T',
        'Rs.250.00 debited from your HDFC Bank RuPay Credit Card XX1234 to swiggy.stores@axb SWIGGY on 01-05-25. '
            'UPI Ref No 512345678901. Not you? Call 18002586161',
      ));
      expect(t.channel, TransactionChannel.upi);
      expect(t.merchantName, 'Swiggy');
      expect(t.cardLast4, '1234');
    });

    test('International spend keeps the foreign currency', () {
      final t = expectTxn(parse(
        'VM-ICICIT-T',
        'USD 25.00 spent using ICICI Bank Card XX5678 on 01-May-25 on NETFLIX.COM. Avl Limit: INR 1,00,000.00.',
      ));
      expect(t.currency, 'USD');
      expect(t.amount, 25.00);
      expect(t.isInternational, isTrue);
      expect(t.category, SpendCategory.subscriptions);
    });

    test('Executed e-mandate debit is a real transaction (not a notice)', () {
      final t = expectTxn(parse(
        'AD-HDFCBK-T',
        'Rs.649.00 has been debited from your HDFC Bank Credit Card XX1234 towards NETFLIX via e-mandate (SI).',
      ));
      expect(t.merchantName, 'Netflix');
      expect(t.category, SpendCategory.subscriptions);
    });

    test('Card fees and finance charges are detected as Fees & Charges', () {
      final fee = expectTxn(parse(
        'JD-SBICRD-S',
        'Annual fee of Rs.499.00 + GST has been charged to your SBI Credit Card ending 4321 on 01/05/25.',
      ));
      expect(fee.category, SpendCategory.fees);
      expect(fee.merchantName, 'Annual Fee');

      final interest = expectTxn(parse(
        'JD-SBICRD-S',
        'Finance charges of Rs 1,234.56 have been levied on your SBI Credit Card ending 4321.',
      ));
      expect(interest.category, SpendCategory.fees);
      expect(interest.merchantName, 'Finance Charges');
      expect(interest.amount, 1234.56);
    });

    test('Alert carrying an anti-fraud "never share OTP" footer is still accepted', () {
      final t = expectTxn(parse(
        'VM-ICICIT-T',
        'INR 999.00 spent using ICICI Bank Card XX5678 on 01-May-25 on MYNTRA. Never share your OTP/CVV with anyone. '
            'Call 1800 2662 if not you.',
      ));
      expect(t.merchantName, 'Myntra');
    });
  });

  group('Positive: credits, refunds and payments', () {
    test('ICICI refund is a refund with merchant from "from <merchant>"', () {
      final t = expectTxn(parse(
        'VM-ICICIT-T',
        'Refund of INR 499.00 from AMAZON has been credited to your ICICI Bank Credit Card XX5678 on 02-May-25.',
        at: DateTime(2025, 5, 2, 9),
      ));
      expect(t.type, TransactionType.refund);
      expect(t.merchantName, 'Amazon');
      expect(t.signedSpend, -499.00);
    });

    test('SBI reversal', () {
      final t = expectTxn(parse(
        'JD-SBICRD-S',
        'Reversal of Rs.1,234.00 at AMAZON credited to your SBI Credit Card ending 4321 on 01/05/25.',
      ));
      expect(t.type, TransactionType.reversal);
      expect(t.merchantName, 'Amazon');
    });

    test('Bill payment received is a payment and excluded from spend', () {
      final t = expectTxn(parse(
        'AD-HDFCBK-T',
        'Payment of Rs 15,000.00 received towards your HDFC Bank Credit Card ending 1234 on 01-05-2025. Thank you.',
      ));
      expect(t.type, TransactionType.payment);
      expect(t.signedSpend, 0);
      expect(t.merchantName, 'Card Bill Payment');
    });
  });

  group('Bill / statement notices', () {
    test('HDFC statement with total, minimum and due date', () {
      final outcome = parse(
        'AD-HDFCBK-S',
        'Your HDFC Bank Credit Card ending 1234 statement has been generated. Total Amt Due: Rs.12,345.67, '
            'Min Amt Due: Rs.620.00, Payment Due Date: 20-05-2025.',
      );
      expect(outcome, isA<ParsedBillNotice>());
      final BillNotice bill = (outcome as ParsedBillNotice).notice;
      expect(bill.bankCode, 'HDFC');
      expect(bill.cardLast4, '1234');
      expect(bill.totalDue, 12345.67);
      expect(bill.minimumDue, 620.00);
      expect(bill.dueDate, DateTime(2025, 5, 20));
    });

    test('ICICI statement with semicolons and "Due by"', () {
      final outcome = parse(
        'VM-ICICIT-S',
        'ICICI Bank Credit Card XX5678 Statement: Total Amount Due INR 22,000.00; Minimum Amount Due INR 1,100.00; '
            'Due by 20-May-25.',
      );
      final bill = (outcome as ParsedBillNotice).notice;
      expect(bill.totalDue, 22000.00);
      expect(bill.minimumDue, 1100.00);
      expect(bill.dueDate, DateTime(2025, 5, 20));
    });

    test('SBI Card payment reminder', () {
      final outcome = parse(
        'JD-SBICRD-S',
        'Reminder: Payment of Rs.8,765.43 for your SBI Credit Card ending 4321 is due on 15/05/25. '
            'Please ignore if already paid.',
      );
      final bill = (outcome as ParsedBillNotice).notice;
      expect(bill.totalDue, 8765.43);
      expect(bill.dueDate, DateTime(2025, 5, 15));
    });
  });

  group('Negative: filtered non-transaction messages', () {
    test('OTP for a card transaction', () {
      expect(
        expectRejected(parse('VM-ICICIT-T',
            '482913 is the OTP for transaction of INR 1,234.00 at AMAZON on your ICICI Bank Credit Card XX5678. '
            'Valid for 5 mins. Do not share OTP with anyone.')),
        SmsRejectReason.otp,
      );
      expect(
        expectRejected(parse('AD-HDFCBK-T',
            'OTP is 551209 for txn of INR 500.00 at SWIGGY on HDFC Bank card ending 1234. Valid till 10:15. Do not share.')),
        SmsRejectReason.otp,
      );
      expect(
        expectRejected(parse('JD-SBICRD-S',
            'OTP for transaction of Rs.999 at FLIPKART on SBI Card ending 4321 is 778812. Do not share it with anyone.')),
        SmsRejectReason.otp,
      );
    });

    test('Promotional header suffix -P', () {
      expect(
        expectRejected(parse('VM-HDFCBK-P', 'Spend Rs.5,000 on your HDFC Bank Credit Card and get 10% cashback!')),
        SmsRejectReason.promotional,
      );
    });

    test('Promotional body from a legacy (suffix-less) header', () {
      expect(
        expectRejected(parse('VM-HDFCBK',
            'Get a pre-approved Personal Loan of up to Rs.5,00,000 on your HDFC Bank Credit Card. Apply now: hdfcbk.io/x')),
        SmsRejectReason.promotional,
      );
    });

    test('E-mandate registration and pre-debit notices are not spends', () {
      expect(
        expectRejected(parse('AD-HDFCBK-S',
            'E-mandate registered: Rs 649.00 will be debited on 05-06-2025 from your HDFC Bank Credit Card XX1234 for NETFLIX.')),
        SmsRejectReason.mandateNotice,
      );
      expect(
        expectRejected(parse('VM-ICICIT-S',
            'Pre-debit notification: Rs 199 will be charged on 05-Jun-25 to your ICICI Bank Credit Card XX5678 for SPOTIFY via e-mandate.')),
        SmsRejectReason.mandateNotice,
      );
    });

    test('Declined transaction', () {
      expect(
        expectRejected(parse('VM-AXISBK-T',
            'Transaction of INR 5,000.00 on your Axis Bank Credit Card XX7765 at FLIPKART has been declined due to insufficient limit.')),
        SmsRejectReason.declined,
      );
    });

    test('Debit card and bank-account UPI debits are out of scope', () {
      expect(
        expectRejected(parse('AD-HDFCBK-T',
            'Rs.500.00 spent on HDFC Bank Debit Card xx5678 at BIGBASKET on 01-05-25.')),
        SmsRejectReason.notCreditCard,
      );
      expect(
        expectRejected(parse('AD-HDFCBK-S',
            'Rs.500.00 debited from A/c XX5678 on 01-05-25 to VPA rahul@okaxis (UPI Ref No 512345678901). Not you? Call 18002586161 -HDFC Bank')),
        SmsRejectReason.notCreditCard,
      );
    });

    test('Unknown commercial sender and spoofed phone-number sender', () {
      expect(
        expectRejected(parse('VM-SWIGGY-S', 'Your order of Rs 450 has been placed and will be delivered soon.')),
        SmsRejectReason.unknownSender,
      );
      expect(
        expectRejected(parse('+919876543210',
            'Rs.15,000.00 spent on your HDFC Bank Credit Card XX1234 at APPLE STORE. Call 9876500000 if not you.')),
        SmsRejectReason.personalNumber,
      );
    });

    test('Informational limit-change message without a transaction verb', () {
      expect(
        expectRejected(parse('AD-HDFCBK-S', 'Your HDFC Bank Credit Card XX1234 limit has been enhanced to Rs 5,00,000.')),
        SmsRejectReason.informational,
      );
    });
  });

  group('Pasted SMS (iOS fallback)', () {
    test('Bank inferred from body when sender is unknown', () {
      final t = expectTxn(parse(
        '',
        'Spent Rs.399.00 On HDFC Bank Card 1234 At UBER INDIA On 2025-04-30:22:10:01.Not You? Call 18002586161',
        origin: SmsOrigin.pasted,
      ));
      expect(t.source, TransactionSource.pastedSms);
      expect(t.bankCode, 'HDFC');
      expect(t.merchantName, 'Uber');
      expect(t.category, SpendCategory.travel);
    });
  });

  group('Deduplication', () {
    test('Same SMS parsed twice yields the same dedupe hash', () {
      const body = 'INR 1,234.00 spent using ICICI Bank Card XX5678 on 01-May-25 on SWIGGY. Avl Limit: INR 1,23,456.78.';
      final a = expectTxn(parse('VM-ICICIT-T', body));
      final b = expectTxn(parse('JX-ICICIT-T', body));
      expect(a.id, b.id);
      expect(a.id.length, 32);
    });

    test('Two identical purchases received at different times are distinct', () {
      const body = 'INR 40.00 spent using ICICI Bank Card XX5678 on 01-May-25 on METRO RAIL. Avl Limit: INR 1,00,000.00.';
      final a = expectTxn(parse('VM-ICICIT-T', body, at: DateTime(2025, 5, 1, 9, 0, 0)));
      final b = expectTxn(parse('VM-ICICIT-T', body, at: DateTime(2025, 5, 1, 18, 30, 0)));
      expect(a.id, isNot(b.id));
    });
  });

  group('MerchantCategorizer', () {
    final categorizer = MerchantCategorizer();

    test('normalises aggregator prefixes and corporate suffixes', () {
      expect(categorizer.categorize('PAYU*SWIGGY').name, 'Swiggy');
      expect(categorizer.categorize('AMAZON PAY INDIA PVT LTD').name, 'Amazon');
      expect(categorizer.categorize('RAZORPAY*NETFLIX').category, SpendCategory.subscriptions);
    });

    test('keyword fallback and display name cleanup', () {
      final info = categorizer.categorize('SHREE GANESH MEDICOS PVT LTD 0042');
      expect(info.category, SpendCategory.health);
      expect(info.name, 'Shree Ganesh Medicos');
      expect(info.isKnownBrand, isFalse);
    });

    test('unknown VPAs are not exposed as merchant names', () {
      final info = categorizer.categorize('rahul.sharma@okaxis');
      expect(info.name, 'UPI Merchant');
    });
  });
}
