// Recognises the documents people actually scan, from the characters read off
// them.
//
// Everything here is pattern matching over OCR text: the shape of an ID number,
// the fixed labels a licence prints, the machine-readable zone of a passport.
// It exists because the generic document-word table in
// `scan_document_outline.dart` can only say what a page calls itself, and the
// papers worth filing — an ID card, a driving licence, a business licence, a
// till receipt — mostly do not print their own name where a headline would be.
// They are recognisable by their *structure*, which is what this file reads.
//
// Deliberately Flutter-free so the rules are unit-testable.

import 'scan_document_outline.dart' show scanTextLines;

/// How the label and tag for a recognised kind should be spelt.
enum ScanLabelLanguage { chinese, english }

/// The documents this recogniser can name.
enum ScanDocumentKind {
  passport,
  idCard,
  driverLicense,
  vehicleLicense,
  residencePermit,
  travelPermit,
  socialSecurityCard,
  businessLicense,
  invoice,
  receipt,
  posSlip,
  bankCard,
  boardingPass,
  trainTicket,
  businessCard,
}

/// Tag filed under each kind, in [ScanLabelLanguage.chinese].
const Map<ScanDocumentKind, String> kScanDocumentKindTagsZh = {
  ScanDocumentKind.passport: '护照',
  ScanDocumentKind.idCard: '身份证',
  ScanDocumentKind.driverLicense: '驾照',
  ScanDocumentKind.vehicleLicense: '行驶证',
  ScanDocumentKind.residencePermit: '居住证',
  ScanDocumentKind.travelPermit: '通行证',
  ScanDocumentKind.socialSecurityCard: '社保卡',
  ScanDocumentKind.businessLicense: '营业执照',
  ScanDocumentKind.invoice: '发票',
  ScanDocumentKind.receipt: '收据',
  ScanDocumentKind.posSlip: '小票',
  ScanDocumentKind.bankCard: '银行卡',
  ScanDocumentKind.boardingPass: '登机牌',
  ScanDocumentKind.trainTicket: '车票',
  ScanDocumentKind.businessCard: '名片',
};

/// Tag filed under each kind, in [ScanLabelLanguage.english].
const Map<ScanDocumentKind, String> kScanDocumentKindTagsEn = {
  ScanDocumentKind.passport: 'passport',
  ScanDocumentKind.idCard: 'id-card',
  ScanDocumentKind.driverLicense: 'driving-licence',
  ScanDocumentKind.vehicleLicense: 'vehicle-registration',
  ScanDocumentKind.residencePermit: 'residence-permit',
  ScanDocumentKind.travelPermit: 'travel-permit',
  ScanDocumentKind.socialSecurityCard: 'social-security',
  ScanDocumentKind.businessLicense: 'business-licence',
  ScanDocumentKind.invoice: 'invoice',
  ScanDocumentKind.receipt: 'receipt',
  ScanDocumentKind.posSlip: 'till-receipt',
  ScanDocumentKind.bankCard: 'bank-card',
  ScanDocumentKind.boardingPass: 'boarding-pass',
  ScanDocumentKind.trainTicket: 'ticket',
  ScanDocumentKind.businessCard: 'business-card',
};

/// What a page was recognised as, plus whatever detail is worth its title.
class ScannedDocumentKind {
  const ScannedDocumentKind(this.kind, {this.subject});

  final ScanDocumentKind kind;

  /// The name printed on the document, when one could be read: the card
  /// holder's name, the licensed company, the bearer of a passport. Null when
  /// the page is one of these things but its holder could not be made out.
  final String? subject;

  /// The tag to file this under in [language].
  String tag(ScanLabelLanguage language) => language == ScanLabelLanguage.english
      ? kScanDocumentKindTagsEn[kind]!
      : kScanDocumentKindTagsZh[kind]!;
}

/// Whether [haystack] mentions any of [words].
///
/// Both sides are written without internal spaces, so a word survives whichever
/// way OCR decided to split it: `注册资本` and `注 册 资 本` both match, and so
/// do `BOARDING PASS` and its joined form.
bool _hits(String haystack, Iterable<String> words) =>
    words.any((word) => haystack.contains(word));

/// How many of [words] [haystack] mentions.
int _countHits(String haystack, Iterable<String> words) =>
    words.fold(0, (total, word) => haystack.contains(word) ? total + 1 : total);

const List<String> _kPassportWords = [
  '中华人民共和国护照',
  '护照号码',
  '护照签发',
  '护照类型',
  '护照',
  'passport',
];

const List<String> _kIdCardWords = [
  '居民身份证',
  '公民身份号码',
  '身份证号',
  '身份证号码',
];

/// What an ID card prints and almost nothing else does — counted rather than
/// trusted individually, because each of these on its own is ordinary Chinese.
const List<String> _kIdCardLabels = [
  '姓名',
  '性别',
  '民族',
  '出生',
  '住址',
  '公民身份',
  '签发机关',
  '有效期限',
];

const List<String> _kDriverLicenseWords = [
  '机动车驾驶证',
  '准驾车型',
  '初次领证日期',
  '驾驶证号',
  'drivinglicence',
  'driverlicense',
];

const List<String> _kVehicleLicenseWords = [
  '行驶证',
  '车辆识别代号',
  '品牌型号',
  '核定载人数',
  '注册日期',
  '发动机号码',
];

const List<String> _kResidencePermitWords = [
  '居住证',
  '暂住登记',
  'residencepermit',
];

const List<String> _kTravelPermitWords = [
  '往来港澳通行证',
  '港澳通行证',
  '往来台湾通行证',
  '台湾居民来往大陆通行证',
  '台胞证',
  '边境管理区通行证',
];

const List<String> _kSocialSecurityWords = [
  '社会保障卡',
  '社保卡',
  '社会保障号码',
  '医疗保障',
  '医保卡',
  '参保地',
];

const List<String> _kBusinessLicenseWords = [
  '营业执照',
  '统一社会信用代码',
  '法定代表人',
  '登记机关',
  '经营范围',
  '注册资本',
  '组成形式',
];

const List<String> _kInvoiceWords = [
  '发票号码',
  '发票代码',
  '纳税人识别号',
  '价税合计',
  '开票日期',
  '发票专用章',
  '增值税专用发票',
  '增值税电子普通发票',
  '电子发票',
  '发票',
];

const List<String> _kInvoiceLabels = [
  '销货单位',
  '购买方',
  '税率',
  '税额',
  '开票人',
  '收款人',
  '校验码',
];

const List<String> _kReceiptWords = ['收据', '收条', '收款凭证', '收款收据'];

const List<String> _kPosSlipWords = [
  '收银',
  '结账单',
  '结账小票',
  '交易凭条',
  '购物小票',
  '谢谢惠顾',
];

const List<String> _kPosSlipLabels = [
  '实付',
  '找零',
  '应收',
  '应付',
  '商户名称',
  '商户号',
  '终端号',
  '交易时间',
  '交易类型',
  '收银台',
  '欢迎光临',
  '合计',
];

const List<String> _kBankCardWords = [
  '银联',
  'unionpay',
  '信用卡',
  '储蓄卡',
  '贷记卡',
  'creditcard',
  'debitcard',
];

const List<String> _kBankCardLabels = ['持卡人', 'cardholder', '有效期', '卡号'];

const List<String> _kBoardingPassWords = [
  '登机牌',
  'boardingpass',
  '登机口',
];

const List<String> _kBoardingPassLabels = [
  '航班号',
  '座位号',
  'gate',
  'seat',
  'flight',
];

const List<String> _kTrainTicketWords = [
  '火车票',
  '动车组',
  'trainticket',
  '高铁',
];

const List<String> _kTrainTicketLabels = [
  '车次',
  '检票口',
  '乘车日期',
  '车厢',
];

const List<String> _kBusinessCardContact = [
  '手机',
  '电话',
  '邮箱',
  '电子邮箱',
  '传真',
  '网址',
  '有限公司',
  '总经理',
  '经理',
  'tel',
  'mobile',
  'email',
  '@',
];

/// Eighteen digits closing in a check character: the mainland ID number. The
/// pattern deliberately takes ASCII digits only, since a page of Árabic-Indic
/// or full-width numerals is not an ID card whichever way it is read.
final RegExp _kIdNumber = RegExp(r'[1-9]\d{16}[\dXx]');

/// Weights of the GB 11643-1999 checksum, and the character each remainder maps
/// to.
const List<int> _kIdWeights = [
  7,
  9,
  10,
  5,
  8,
  4,
  2,
  1,
  6,
  3,
  7,
  9,
  10,
  5,
  8,
  4,
  2,
];
const String _kIdCheckChars = '10X98765432';

/// Whether an ID number's own check character agrees with its digits.
///
/// Without this every eighteen-digit figure on the page — a bank card, a serial
/// number, a run-together pair of dates — would claim to be somebody's ID card.
bool _isValidIdNumber(String value) {
  final digits = value.toUpperCase();
  var sum = 0;
  for (var i = 0; i < _kIdWeights.length; i++) {
    final digit = int.tryParse(digits[i]);
    if (digit == null) return false;
    sum += digit * _kIdWeights[i];
  }
  return _kIdCheckChars[sum % 11] == digits[17];
}

/// The eighteen-character Unified Social Credit Code a mainland business
/// licence is identified by. The character set leaves out the five letters the
/// standard forbids, which is what keeps an arbitrary eighteen-character string
/// from passing for a licence.
final RegExp _kCreditCode = RegExp(
  r'[0-9A-HJ-NPQRTUWXY]{2}\d{6}[0-9A-HJ-NPQRTUWXY]{10}',
);

/// One of the letters the credit-code alphabet allows, which digits are not.
final RegExp _kCreditCodeLetter = RegExp(r'[A-HJ-NPQRTUWXY]');

/// Whether [upper] carries a Unified Social Credit Code.
///
/// Requires a letter somewhere in the match: read strictly as characters the
/// pattern is satisfied by eighteen *digits* too, and half the long numbers on
/// a page — serials, run-together dates — would then claim to be a licence.
/// Demanding the one thing digits cannot supply is what separates the two.
bool _hasCreditCode(String upper) => _kCreditCode
    .allMatches(upper)
    .any((match) => _kCreditCodeLetter.hasMatch(match.group(0)!));

/// Whether [squashed] carries an ID number that agrees with its own checksum.
bool _hasValidIdNumber(String squashed) =>
    _kIdNumber.allMatches(squashed).any((m) => _isValidIdNumber(m.group(0)!));

/// Two lines of capitals, digits and `<` fillers: the machine-readable zone
/// running along the bottom of a travel document, and the most reliable thing
/// OCR ever gets off one.
final RegExp _kMrzLine = RegExp(r'^[PIV][A-Z<0-9]{27,}$');

/// The machine-readable zone on the page, or null when there is none.
///
/// One qualifying row already settles it — nothing else in a page's text is 28
/// characters of capitals and `<` — so a second row is not insisted on.
String? _machineReadableZone(List<String> lines) {
  for (final line in lines) {
    final candidate = line.replaceAll(' ', '');
    if (_kMrzLine.hasMatch(candidate)) return candidate;
  }
  return null;
}

/// The name a travel document's zone spells out.
///
/// `POCHNZHANG<<SAN<<<<` is *ZHANG San*: surname first, then `<` where the
/// given name ends, then fillers. Emitting it title-cased rather than shouting
/// keeps `ZHANG SAN` out of a memo title.
String? _nameFromMrz(String mrz) {
  final body = mrz.length > 5 ? mrz.substring(5) : mrz;
  final surnameEnd = body.indexOf('<<');
  if (surnameEnd < 0) return null;
  final surname = body.substring(0, surnameEnd).replaceAll('<', '').trim();
  final rest = body.substring(surnameEnd + 2);
  final givenEnd = rest.indexOf('<');
  final given = (givenEnd < 0 ? rest : rest.substring(0, givenEnd))
      .replaceAll('<', ' ')
      .trim();
  if (surname.isEmpty) return null;
  return _titleCaseLatin(given.isEmpty ? surname : '$surname $given');
}

String _titleCaseLatin(String value) => value
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
    .join(' ');

final RegExp _kChineseName = RegExp(r'^[一-龥·]{2,15}$');
final RegExp _kLatinName = RegExp(r"^[A-Za-z][A-Za-z .'\-]{1,30}$");

bool _looksLikeChineseName(String value) => _kChineseName.hasMatch(value);

bool _looksLikeLatinName(String value) => _kLatinName.hasMatch(value);

bool _looksLikeCompanyName(String value) =>
    value.runes.length >= 4 &&
    RegExp(r'^[一-龥A-Za-z0-9()（）·\s]{4,40}$').hasMatch(value);

/// Every request for a card holder's name, in the forms OCR hands them back in.
const List<String> _kSubjectNameLabels = ['姓名', '名称', '名 称', 'Name', 'NAME'];

/// The value printed after one of [labels] — `姓名 张三`, `名称：某某公司`.
///
/// Takes what follows the label on its own line when there is anything, and
/// otherwise the next line that is not itself another label: OCR routinely puts
/// a value under its caption rather than beside it. [limit] is what stops a
/// paragraph being read as a name.
String? _valueAfterLabel(
  List<String> lines,
  Iterable<String> labels, {
  required int limit,
  bool Function(String)? acceptable,
}) {
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    for (final label in labels) {
      final at = line.indexOf(label);
      if (at < 0) continue;

      final trailing = line.substring(at + label.length).trim();
      final candidates = <String?>[
        trailing.isEmpty ? null : trailing,
        i + 1 < lines.length ? lines[i + 1] : null,
      ];
      for (final candidate in candidates) {
        final value = _cleanValue(candidate, limit: limit);
        if (value == null) continue;
        if (acceptable != null && !acceptable(value)) continue;
        return value;
      }
    }
  }
  return null;
}

String? _cleanValue(String? raw, {required int limit}) {
  if (raw == null) return null;
  // Leading punctuation is the label's remnant, not part of the value.
  final value = raw
      .replaceAll(RegExp(r'^[\s:：.\-—_]+'), '')
      .replaceAll(RegExp(r'[\s:：.。，,]+$'), '')
      .trim();
  if (value.isEmpty) return null;
  if (value.runes.length > limit) return null;
  // Containing a colon means it is another label, not the value of this one.
  if (value.contains('：') || value.contains(':')) return null;
  return value;
}

String? _personName(List<String> lines) => _valueAfterLabel(
  lines,
  _kSubjectNameLabels,
  limit: 20,
  acceptable: (value) =>
      _looksLikeChineseName(value) || _looksLikeLatinName(value),
);

/// The person or organisation [kind] belongs to, or null when the page does not
/// state one legibly.
///
/// Deliberately conservative wherever it could be wrong: a document filed under
/// the wrong *name* is worse than one filed under no name at all, since the
/// type tag is what is being searched for and the name only helps read a list.
String? _subjectFor(ScanDocumentKind kind, List<String> lines) {
  switch (kind) {
    case ScanDocumentKind.idCard:
    case ScanDocumentKind.driverLicense:
    case ScanDocumentKind.residencePermit:
      return _personName(lines);

    case ScanDocumentKind.passport:
      final zone = _machineReadableZone(lines);
      final spelt = zone == null ? null : _nameFromMrz(zone);
      return spelt ?? _personName(lines);

    case ScanDocumentKind.businessLicense:
      return _valueAfterLabel(
        lines,
        const ['名称', '名 称', '企业名称'],
        limit: 40,
        acceptable: _looksLikeCompanyName,
      );

    case ScanDocumentKind.businessCard:
      if (lines.isEmpty) return null;
      final headline = lines.firstWhere(
        (line) => line.runes.length >= 2 && line.runes.length <= 16,
        orElse: () => lines.first,
      );
      final value = _cleanValue(headline, limit: 16);
      if (value == null) return null;
      return _looksLikeChineseName(value) || _looksLikeLatinName(value)
          ? value
          : null;

    default:
      return null;
  }
}

/// Recognises [rawText] as one of [ScanDocumentKind], or returns null.
///
/// Ordered most-specific first, and a page can only be one thing: a driving
/// licence carries a name and an ID number too, and is still a licence rather
/// than also an ID card. Every rule insists on something structural — a word
/// only that document prints, a number shape nothing else uses — rather than
/// counting how many times a page says `card`.
ScannedDocumentKind? classifyScannedDocument(String rawText) {
  final lines = scanTextLines(rawText);
  if (lines.isEmpty) return null;

  // OCR splits words unpredictably, so spacing is removed before anything is
  // looked for: what is being matched is structure, not phrasing.
  final squashed = lines.map((line) => line.replaceAll(' ', '')).join('\n');
  final haystack = squashed.toLowerCase();
  final upper = squashed.toUpperCase();
  final mrz = _machineReadableZone(lines);

  ScanDocumentKind? kind;
  if (mrz != null && mrz.startsWith('P')) {
    kind = ScanDocumentKind.passport;
  } else if (_hits(haystack, _kPassportWords)) {
    // The machine-readable zone is the reliable answer, but it is the strip of
    // characters OCR most often loses, so the words the booklet prints in full
    // have to be able to carry it on their own.
    kind = ScanDocumentKind.passport;
  } else if (_hits(haystack, _kIdCardWords)) {
    kind = ScanDocumentKind.idCard;
  } else if (_hits(haystack, _kDriverLicenseWords)) {
    kind = ScanDocumentKind.driverLicense;
  } else if (_hits(haystack, _kVehicleLicenseWords)) {
    kind = ScanDocumentKind.vehicleLicense;
  } else if (_hits(haystack, _kResidencePermitWords)) {
    kind = ScanDocumentKind.residencePermit;
  } else if (_hits(haystack, _kTravelPermitWords)) {
    kind = ScanDocumentKind.travelPermit;
  } else if (_hits(haystack, _kSocialSecurityWords)) {
    kind = ScanDocumentKind.socialSecurityCard;
  } else if (_hits(haystack, _kBusinessLicenseWords) || _hasCreditCode(upper)) {
    kind = ScanDocumentKind.businessLicense;
  } else if (_hits(haystack, _kInvoiceWords) ||
      _countHits(haystack, _kInvoiceLabels) >= 3) {
    kind = ScanDocumentKind.invoice;
  } else if (_hits(haystack, _kReceiptWords)) {
    kind = ScanDocumentKind.receipt;
  } else if (_hits(haystack, _kPosSlipWords) ||
      _countHits(haystack, _kPosSlipLabels) >= 2) {
    kind = ScanDocumentKind.posSlip;
  } else if (_hits(haystack, _kBoardingPassWords) ||
      (_hits(haystack, _kBoardingPassLabels) && squashed.runes.length < 200)) {
    kind = ScanDocumentKind.boardingPass;
  } else if (_hits(haystack, _kTrainTicketWords) ||
      _countHits(haystack, _kTrainTicketLabels) >= 2) {
    kind = ScanDocumentKind.trainTicket;
  } else if (_hits(haystack, _kBankCardWords) ||
      _countHits(haystack, _kBankCardLabels) >= 2) {
    kind = ScanDocumentKind.bankCard;
  } else if (lines.length <= 14 &&
      squashed.runes.length <= 220 &&
      _countHits(haystack, _kBusinessCardContact) >= 3) {
    // Short, contact-heavy and nothing else matched: the one kind of paper
    // whose entire purpose is somebody's details.
    kind = ScanDocumentKind.businessCard;
  }

  // An ID number that agrees with its checksum outranks anything weaker: a
  // licence carries one as well, and it is the card alone whose subject *is*
  // the number.
  if (kind == null &&
      _hasValidIdNumber(upper) &&
      _countHits(haystack, _kIdCardLabels) >= 2) {
    kind = ScanDocumentKind.idCard;
  }

  if (kind == null) return null;
  return ScannedDocumentKind(kind, subject: _subjectFor(kind, lines));
}
