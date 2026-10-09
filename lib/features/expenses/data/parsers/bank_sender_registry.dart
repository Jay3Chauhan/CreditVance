/// TRAI commercial-communication category encoded in the header suffix
/// (`-P`, `-S`, `-T`, `-G`), mandatory since May 2025.
enum SenderCategory { promotional, service, transactional, government, unknown }

/// Parsed Indian A2P SMS header such as `AD-HDFCBK`, `VM-ICICIT-T` or `JD-SBICRD-S`.
///
/// Format: `<2-letter operator/circle prefix>-<header core>[-<category suffix>]`.
/// Some handsets drop the prefix (`HDFCBK`) or show it without a dash.
class SenderId {
  final String raw;
  final String? operatorPrefix;

  /// Upper-cased header core, e.g. `HDFCBK`.
  final String core;
  final SenderCategory category;

  /// True for long numeric senders (`+9198...`) — never trusted as a bank.
  final bool isPhoneNumber;

  const SenderId({
    required this.raw,
    required this.operatorPrefix,
    required this.core,
    required this.category,
    required this.isPhoneNumber,
  });

  static final RegExp _phoneRe = RegExp(r'^\+?\d[\d\s-]{6,}$');

  /// Parses a raw SMS `address` into its components.
  factory SenderId.parse(String raw) {
    final trimmed = raw.trim().toUpperCase();
    if (trimmed.isEmpty) {
      return const SenderId(
        raw: '',
        operatorPrefix: null,
        core: '',
        category: SenderCategory.unknown,
        isPhoneNumber: false,
      );
    }
    if (_phoneRe.hasMatch(trimmed)) {
      return SenderId(
        raw: trimmed,
        operatorPrefix: null,
        core: trimmed,
        category: SenderCategory.unknown,
        isPhoneNumber: true,
      );
    }

    final parts = trimmed.split('-').where((p) => p.isNotEmpty).toList();
    var category = SenderCategory.unknown;
    if (parts.length > 1 && parts.last.length == 1) {
      category = switch (parts.last) {
        'P' => SenderCategory.promotional,
        'S' => SenderCategory.service,
        'T' => SenderCategory.transactional,
        'G' => SenderCategory.government,
        _ => SenderCategory.unknown,
      };
      if (category != SenderCategory.unknown) parts.removeLast();
    }
    String? prefix;
    if (parts.length > 1 && parts.first.length == 2) {
      prefix = parts.removeAt(0);
    }
    return SenderId(
      raw: trimmed,
      operatorPrefix: prefix,
      core: parts.join(),
      category: category,
      isPhoneNumber: false,
    );
  }

  /// Transactional or service headers carry bank alerts.
  bool get isTransactionalOrService =>
      category == SenderCategory.transactional || category == SenderCategory.service;
}

/// Issuer profile used to recognise bank alert senders.
class BankProfile {
  /// Stable registry code shared with the backend (`bank_code`).
  final String code;
  final String displayName;

  /// DLT header cores registered by the issuer for alerts.
  final List<String> senderKeys;

  /// Lower-case phrases that identify the issuer inside an SMS body
  /// (used for pasted SMS where the sender is unknown).
  final List<String> bodyAliases;

  const BankProfile({
    required this.code,
    required this.displayName,
    required this.senderKeys,
    required this.bodyAliases,
  });
}

/// Registry of Indian credit card issuers and their SMS header cores.
///
/// This is a bundled seed list. Headers change, so production builds should
/// refresh it from `GET /expenses/sender-registry` and verify entries against
/// TRAI's published header list.
class BankSenderRegistry {
  final List<BankProfile> banks;

  const BankSenderRegistry({this.banks = defaultBanks});

  static const BankProfile unknownBank = BankProfile(
    code: 'UNKNOWN',
    displayName: 'Card',
    senderKeys: [],
    bodyAliases: [],
  );

  static const List<BankProfile> defaultBanks = [
    BankProfile(
      code: 'HDFC',
      displayName: 'HDFC Bank',
      senderKeys: ['HDFCBK', 'HDFCCC'],
      bodyAliases: ['hdfc bank', 'hdfc'],
    ),
    BankProfile(
      code: 'ICICI',
      displayName: 'ICICI Bank',
      senderKeys: ['ICICIB', 'ICICIT'],
      bodyAliases: ['icici bank', 'icici'],
    ),
    BankProfile(
      code: 'SBICARD',
      displayName: 'SBI Card',
      senderKeys: ['SBICRD', 'SBICARD'],
      bodyAliases: ['sbi credit card', 'sbi card', 'sbicard', 'sbi'],
    ),
    BankProfile(
      code: 'AXIS',
      displayName: 'Axis Bank',
      senderKeys: ['AXISBK', 'AXISCC'],
      bodyAliases: ['axis bank', 'axis'],
    ),
    BankProfile(
      code: 'KOTAK',
      displayName: 'Kotak Mahindra Bank',
      senderKeys: ['KOTAKB', 'KOTAKC'],
      bodyAliases: ['kotak mahindra', 'kotak bank', 'kotak'],
    ),
    BankProfile(
      code: 'AMEX',
      displayName: 'American Express',
      senderKeys: ['AMEXIN', 'AMEX'],
      bodyAliases: ['american express', 'amex'],
    ),
    BankProfile(
      code: 'IDFC',
      displayName: 'IDFC FIRST Bank',
      senderKeys: ['IDFCFB', 'IDFCBK'],
      bodyAliases: ['idfc first', 'idfc'],
    ),
    BankProfile(
      code: 'AU',
      displayName: 'AU Small Finance Bank',
      senderKeys: ['AUBANK', 'AUCARD'],
      bodyAliases: ['au small finance', 'au bank'],
    ),
    BankProfile(
      code: 'ONECARD',
      displayName: 'OneCard',
      senderKeys: ['ONECRD', 'ONECARD'],
      bodyAliases: ['onecard', 'one card'],
    ),
    BankProfile(
      code: 'RBL',
      displayName: 'RBL Bank',
      senderKeys: ['RBLBNK', 'RBLCRD'],
      bodyAliases: ['rbl bank', 'rbl'],
    ),
    BankProfile(
      code: 'YES',
      displayName: 'YES Bank',
      senderKeys: ['YESBNK', 'YESBCC'],
      bodyAliases: ['yes bank'],
    ),
    BankProfile(
      code: 'INDUSIND',
      displayName: 'IndusInd Bank',
      senderKeys: ['INDUSB', 'INDUSL'],
      bodyAliases: ['indusind'],
    ),
    BankProfile(
      code: 'HSBC',
      displayName: 'HSBC',
      senderKeys: ['HSBCIN', 'HSBCBK'],
      bodyAliases: ['hsbc'],
    ),
    BankProfile(
      code: 'SCB',
      displayName: 'Standard Chartered',
      senderKeys: ['SCBANK', 'STANCB'],
      bodyAliases: ['standard chartered', 'stanchart'],
    ),
    BankProfile(
      code: 'FEDERAL',
      displayName: 'Federal Bank',
      senderKeys: ['FEDBNK', 'FEDFIB'],
      bodyAliases: ['federal bank'],
    ),
    BankProfile(
      code: 'BOB',
      displayName: 'BOBCARD',
      senderKeys: ['BOBCRD', 'BOBTXN', 'BOBCARD'],
      bodyAliases: ['bobcard', 'bank of baroda'],
    ),
  ];

  /// All header cores, used to pre-filter the inbox natively so that
  /// non-bank SMS bodies never cross the platform channel.
  List<String> get allSenderKeys => [for (final b in banks) ...b.senderKeys];

  /// Resolves a parsed header to an issuer, or null when unknown.
  BankProfile? resolveSender(SenderId sender) {
    if (sender.isPhoneNumber || sender.core.isEmpty) return null;
    for (final bank in banks) {
      for (final key in bank.senderKeys) {
        if (sender.core == key || sender.core.contains(key)) return bank;
      }
    }
    return null;
  }

  /// Infers the issuer from SMS body text (longest alias wins).
  BankProfile? inferFromBody(String lowerBody) {
    BankProfile? best;
    var bestLen = 0;
    for (final bank in banks) {
      for (final alias in bank.bodyAliases) {
        if (alias.length <= bestLen) continue;
        final re = RegExp('\\b${RegExp.escape(alias)}\\b');
        if (re.hasMatch(lowerBody)) {
          best = bank;
          bestLen = alias.length;
        }
      }
    }
    return best;
  }
}
