// Turns the characters lifted off a scanned page into a memo title and tags.
//
// This is the offline counterpart to the AI reader: it hands back the same
// `ScanMetadataDraft`, so the review screen does not care which of the two made
// a suggestion, but the work here is pattern matching over recognised
// characters rather than reading the page.
//
// The premise is narrow on purpose. Paperwork that gets scanned — contracts,
// invoices, receipts, notices — names itself in its first line or two, and that
// headline is what a title should be. Nothing here tries to summarise prose: a
// page with no recognisable headline is better served by the date fallback than
// by a guess dressed up as understanding.
//
// Deliberately Flutter-free so the matching rules are unit-testable.

import 'memo_scan_metadata.dart';
import 'scan_document_kind.dart'
    show ScannedDocumentKind, ScanLabelLanguage, classifyScannedDocument;

/// Documents that name themselves in their own first line, mapped to the tag a
/// page mentioning one is filed under.
///
/// Insertion order is priority order. Only the first matching word counts, so
/// the list runs from specific to generic: a page whose headline names both
/// 合同 and 协议 is filed as a contract rather than an agreement.
const Map<String, String> kScanDocumentTypeTags = <String, String>{
  '合同': '合同',
  '协议': '协议',
  '发票': '发票',
  '收据': '收据',
  '凭证': '凭证',
  '账单': '账单',
  '对账单': '对账单',
  '清单': '清单',
  '订单': '订单',
  '通知': '通知',
  '公告': '公告',
  '报告': '报告',
  '证明': '证明',
  '说明书': '说明书',
  '申请表': '申请表',
  '审批单': '审批单',
  '委托书': '委托书',
  '授权书': '授权书',
  '简历': '简历',
  '名片': '名片',
  '处方': '处方',
  '病历': '病历',
  '保单': '保单',
  '证书': '证书',
  '纪要': '纪要',
  'invoice': 'invoice',
  'receipt': 'receipt',
  'contract': 'contract',
  'agreement': 'agreement',
  'statement': 'statement',
};

/// Shortest line that can be a headline rather than a form field's label.
const int _kMinHeadlineRunes = 4;

/// [sanitizeScanTitle] caps titles at [kScanMetadataMaxTitleChars]. Anything
/// longer is a paragraph, not a headline, and must not be offered as one.
const int _kMaxHeadlineRunes = kScanMetadataMaxTitleChars;

final RegExp _kHasLetter = RegExp(r'\p{L}', unicode: true);

/// Every non-empty line of [rawText], with runs of whitespace collapsed and
/// letter-spacing inside solid-script words closed up.
///
/// Line structure is the only layout information worth keeping from OCR: it is
/// what separates a headline from the body underneath it.
List<String> scanTextLines(String rawText) {
  final lines = <String>[];
  for (final raw in rawText.split(RegExp(r'[\r\n]+'))) {
    final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (collapsed.isEmpty) continue;
    final line = _tightenLetterSpacing(collapsed);
    if (line.isNotEmpty) lines.add(line);
  }
  return lines;
}

/// Whether [rune] is a space, including the ideographic one OCR emits.
bool _isSpaceRune(int rune) => rune == 0x20 || rune == 0x09 || rune == 0x3000;

/// Whether [rune] belongs to a script set solid, so a gap between two of them
/// is always letter-spacing rather than a word boundary.
bool _isSolidScriptRune(int rune) =>
    (rune >= 0x3400 && rune <= 0x9FFF) || // CJK 统一表意
    (rune >= 0xF900 && rune <= 0xFAFF) || // CJK 兼容表意
    (rune >= 0x3040 && rune <= 0x30FF) || // 平假名 / 片假名
    (rune >= 0xAC00 && rune <= 0xD7AF) || // 谚文
    (rune >= 0xFF00 && rune <= 0xFFEF); // 全角标点与全角字母

/// Closes the gaps OCR leaves inside a letter-spaced headline.
///
/// Contracts and invoices routinely set their own name as `房 屋 租 赁 合 同`.
/// Left as recognised, that spelling matches none of [kScanDocumentTypeTags]
/// and files a memo under a title with the spacing still in it. A gap next to a
/// Latin letter or digit, on the other hand, is a real word boundary — closing
/// it would turn `ACME SUPPLY` into `ACMESUPPLY` — so those are left alone.
String _tightenLetterSpacing(String line) {
  final runes = line.runes.toList();
  final kept = <int>[];
  for (var index = 0; index < runes.length; index++) {
    final rune = runes[index];
    if (!_isSpaceRune(rune) || kept.isEmpty) {
      kept.add(rune);
      continue;
    }
    int? next;
    for (var lookahead = index + 1; lookahead < runes.length; lookahead++) {
      if (_isSpaceRune(runes[lookahead])) continue;
      next = runes[lookahead];
      break;
    }
    if (next != null &&
        _isSolidScriptRune(kept.last) &&
        _isSolidScriptRune(next)) {
      continue; // 字间距，不是词边界
    }
    kept.add(rune);
  }
  return String.fromCharCodes(kept);
}

/// The first document-type word [rawText] mentions, or null.
///
/// Matching ignores case and runs over the tightened lines, so a keyword
/// survives both an uppercase `INVOICE` and a letter-spaced `合 同`.
String? scanDocumentTypeWord(String rawText) {
  final haystack = scanTextLines(rawText).join('\n').toLowerCase();
  for (final word in kScanDocumentTypeTags.keys) {
    if (haystack.contains(word)) return word;
  }
  return null;
}

/// A title and tags for a page whose recognised text is [rawText].
///
/// Returns null only when the page yielded nothing usable at all — no words and
/// no date to fall back on — which a caller should read as "no suggestion",
/// never as an error worth interrupting the user over.
///
/// [fallbackPrefix] names a scan whose text held no headline; callers that know
/// the UI language pass their own, since this file is deliberately not tied to
/// any localisation machinery.
ScanMetadataDraft? outlineScannedText(
  String rawText, {
  required DateTime scannedAt,
  String fallbackPrefix = '扫描件',
  ScanLabelLanguage labels = ScanLabelLanguage.chinese,
}) {
  final lines = scanTextLines(rawText);
  final classified = classifyScannedDocument(rawText);
  final typeWord = scanDocumentTypeWord(rawText);
  if (lines.isEmpty && classified == null && typeWord == null) return null;

  // A recognised card or slip outranks the generic word table: the word table
  // files a driving licence under whatever word its first line happens to
  // contain, whereas the classifier knows what the page actually is.
  final kindTag = classified?.tag(labels);
  final typeTag = kindTag ?? (typeWord == null ? null : kScanDocumentTypeTags[typeWord]);

  // A recognised kind names the note itself, so the page's own headline is only
  // consulted when nothing was recognised.
  final headline = classified == null ? _pickHeadline(lines, typeWord) : null;
  final title = _kindAwareTitle(
    classified,
    headline: headline,
    scannedAt: scannedAt,
    fallbackPrefix: fallbackPrefix,
    labels: labels,
  );
  final tags = sanitizeScanTags(<String>[
    if (typeTag != null) typeTag,
    scannedAt.year.toString(),
  ]);

  return ScanMetadataDraft(title: title, tags: tags, text: rawText);
}

/// What to call a page the classification has an opinion about.
///
/// The type word is the whole title, and it is the short one — `身份证`, not
/// the `中华人民共和国居民身份证` the card prints across its own face. Cards
/// are filed under their type tag anyway, so a title repeating the full
/// inscription says nothing the tag does not, and listing scans is easier when
/// every title of a kind starts the same way.
///
/// The holder's name, when the page gave one up, follows it after a separator:
/// two ID cards in a row are told apart by whose they are, and the type alone
/// would make them look like duplicates. Without a name the date follows
/// instead, which is what keeps a second scan from looking like the first.
String _kindAwareTitle(
  ScannedDocumentKind? classified, {
  required String? headline,
  required DateTime scannedAt,
  required String fallbackPrefix,
  required ScanLabelLanguage labels,
}) {
  if (classified == null) {
    return headline == null
        ? scanDateFallbackTitle(scannedAt, prefix: fallbackPrefix)
        : sanitizeScanTitle(headline);
  }

  final label = classified.tag(labels);
  final subject = classified.subject;
  final titled = subject == null || subject.isEmpty
      ? scanDateFallbackTitle(scannedAt, prefix: label)
      : '$label · $subject';
  return sanitizeScanTitle(titled);
}

/// What to call a scan when the page itself says nothing usable.
String scanDateFallbackTitle(DateTime scannedAt, {String prefix = '扫描件'}) {
  final month = scannedAt.month.toString().padLeft(2, '0');
  final day = scannedAt.day.toString().padLeft(2, '0');
  return '$prefix $month-$day';
}

/// The line that should become the memo's first line, or null.
///
/// A line naming the document wins over position: the page's own title is
/// usually below a letterhead, and picking the letterhead instead would file
/// every invoice under the company that issued it.
String? _pickHeadline(List<String> lines, String? typeWord) {
  if (typeWord != null) {
    for (final line in lines) {
      if (!_mentions(line, typeWord)) continue;
      if (_looksLikeField(line)) continue;
      if (line.runes.length > _kMaxHeadlineRunes) continue;
      if (_isOnlyTheWord(line, typeWord)) continue;
      return line;
    }
  }
  for (final line in lines) {
    if (_looksLikeField(line)) continue;
    if (!_isHeadlineSized(line)) continue;
    return line;
  }
  return null;
}

/// Whether [line] names [word], ignoring case.
bool _mentions(String line, String word) => line.toLowerCase().contains(word);

/// Whether [line] is nothing but [word] — a label rather than a headline.
///
/// A line reading `INVOICE` and nothing else repeats what the tag already says,
/// so the issuer or the invoice number above it is the better title. The
/// Chinese equivalents are shorter than [_kMinHeadlineRunes] and fall through
/// on their own.
bool _isOnlyTheWord(String line, String word) =>
    line.replaceAll(' ', '').toLowerCase() == word;

/// Whether [line] is a labelled field rather than a heading, e.g. `甲方：张三`.
///
/// OCR renders the colon inconsistently, so both widths are treated alike, and
/// a line carrying no letters at all — a bare number, date or amount — cannot
/// be a heading either.
bool _looksLikeField(String line) {
  if (line.contains('：') || line.contains(':')) return true;
  return !_kHasLetter.hasMatch(line);
}

bool _isHeadlineSized(String line) {
  final length = line.runes.length;
  return length >= _kMinHeadlineRunes && length <= _kMaxHeadlineRunes;
}
