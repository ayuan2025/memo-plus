import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/memo_scan_metadata.dart';
import 'package:memos_flutter_app/core/scan_document_outline.dart';

/// The scanner's offline reader.
///
/// Its contract is narrow on purpose: paperwork announces itself in its first
/// line or two, and the rules exist to find that line rather than to understand
/// the page. Every expectation below is a page shape that actually turns up in
/// a stack of contracts and invoices.
void main() {
  final scannedAt = DateTime(2026, 9, 18);

  ScanMetadataDraft? outline(String text) =>
      outlineScannedText(text, scannedAt: scannedAt);

  group('scanTextLines', () {
    test('collapses whitespace and drops blank lines', () {
      expect(scanTextLines('  a  b \n\n  c '), <String>['a b', 'c']);
      expect(scanTextLines('\n\n'), isEmpty);
    });

    test('closes the letter-spacing OCR puts inside a headline', () {
      expect(scanTextLines('房 屋 租 赁 合 同'), <String>['房屋租赁合同']);
      expect(scanTextLines('收\u3000据'), <String>['收据']);
    });

    test('keeps the gaps between Latin words', () {
      expect(scanTextLines('ACME SUPPLY CO., LTD.'), <String>[
        'ACME SUPPLY CO., LTD.',
      ]);
      expect(scanTextLines('Invoice no. 4471'), <String>['Invoice no. 4471']);
    });

    test('closes a gap next to full-width punctuation too', () {
      expect(scanTextLines('甲方 ：张三'), <String>['甲方：张三']);
      expect(scanTextLines('合计 ￥300.00'), <String>['合计￥300.00']);
    });
  });

  group('scanDocumentTypeWord', () {
    test('names the document', () {
      expect(scanDocumentTypeWord('房屋租赁合同'), '合同');
      expect(scanDocumentTypeWord('Tax invoice no. 7'), 'invoice');
    });

    test('prefers the more specific word when a page mentions two', () {
      expect(scanDocumentTypeWord('合同附件：技术服务协议'), '合同');
    });

    test('sees through case and letter-spacing', () {
      expect(scanDocumentTypeWord('INVOICE'), 'invoice');
      expect(scanDocumentTypeWord('房 屋 租 赁 合 同'), '合同');
    });

    test('returns null when the page names nothing', () {
      expect(scanDocumentTypeWord('今天天气不错'), isNull);
    });
  });

  group('outlineScannedText', () {
    test('names a recognised slip after its type, not its letterhead', () {
      // The issuer's name above the slip is not what this note is: the type
      // word is, and it is filed under the same word as a tag.
      final draft = outline('江南贸易有限公司\n增值税专用发票\n发票代码 12345');
      expect(draft?.title, '发票 09-18');
      expect(draft?.tags, <String>['发票', '2026']);
    });

    test('skips a labelled field that merely mentions the type', () {
      final draft = outline('合同编号：HT-2024-001\n房屋租赁合同\n甲方：张三');
      expect(draft?.title, '房屋租赁合同');
    });

    test('reads a letter-spaced contract as a contract', () {
      final draft = outline('合 同 编 号：HT-2026-0091\n房 屋 租 赁 合 同\n出租方（甲方）：张三');
      expect(draft?.title, '房屋租赁合同');
      expect(draft?.tags, <String>['合同', '2026']);
    });

    test('files an uppercase invoice under its number, not its letterhead', () {
      final draft = outline(
        'ACME SUPPLY CO., LTD.\nINVOICE\nInvoice No. INV-2026-4471\n'
        'Date: 12 Sep 2026',
      );
      expect(draft?.title, 'Invoice No. INV-2026-4471');
      expect(draft?.tags, <String>['invoice', '2026']);
    });

    test('titles a recognised slip by its type and date', () {
      // Recognised as a receipt, so the body line is no longer the title: the
      // type word is, and the date is what keeps it distinct from the next one.
      final draft = outline('收 据\n今收到住宿费人民币叁佰元整');
      expect(draft?.title, '收据 09-18');
      expect(draft?.tags, <String>['收据', '2026']);
    });

    test('falls back to the first heading-shaped line', () {
      final draft = outline('会议室使用说明\n请提前预约');
      expect(draft?.title, '会议室使用说明');
      expect(draft?.tags, <String>['2026']);
    });

    test('never promotes a paragraph to a headline', () {
      final paragraph = '甲' * 60;
      final draft = outline('$paragraph\n采购合同');
      expect(draft?.title, '采购合同');
    });

    test('dates a page that carries no usable headline', () {
      final draft = outline('甲方：张三\n乙方：李四');
      expect(draft?.title, '扫描件 09-18');
      expect(draft?.tags, <String>['2026']);
    });

    test('dates a page whose lines are all fields or bare numbers', () {
      final draft = outline('12345\n---');
      expect(draft?.title, '扫描件 09-18');
    });

    test('honours a localised fallback prefix', () {
      final draft = outlineScannedText(
        '甲方：张三',
        scannedAt: scannedAt,
        fallbackPrefix: 'Scan',
      );
      expect(draft?.title, 'Scan 09-18');
    });

    test('returns null only when the page yielded no lines at all', () {
      expect(outline(''), isNull);
      expect(outline('   \n  \t '), isNull);
    });

    test('cleans the headline the way any other suggestion is cleaned', () {
      final draft = outline('# 采购合同 `\n甲方：张三');
      expect(draft!.title, '采购合同');
      expect(
        draft.title.runes.length,
        lessThanOrEqualTo(kScanMetadataMaxTitleChars),
      );
      expect(draft.tags.length, lessThanOrEqualTo(kScanMetadataMaxTags));
      for (final tag in draft.tags) {
        expect(tag, isNot(contains(' ')));
        expect(tag, isNot(startsWith('#')));
      }
    });
  });
}
