import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/scan_document_kind.dart';
import 'package:memos_flutter_app/core/scan_document_outline.dart';

/// A realistic ID card is not a headline plus prose: it is labels with values
/// beside them, a number that has to agree with itself, and no title anywhere on
/// it. These are the pages the generic document-word table in
/// `scan_document_outline.dart` files under whatever word happens to appear
/// first, which is why this file exists.
void main() {
  group('classifyScannedDocument', () {
    test('a resident identity card', () {
      final kind = classifyScannedDocument(
        '中华人民共和国居民身份证\n'
        '签发机关 某市公安局\n'
        '有效期限 2016.05.20-2036.05.20\n'
        '姓名 张三\n'
        '性别 男 民族 汉\n'
        '出生 1990年1月1日\n'
        '住址 某省某市某区某路1号\n'
        '公民身份号码 110105199001011234',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.idCard);
      expect(kind.subject, '张三');
      expect(kind.tag(ScanLabelLanguage.chinese), '身份证');
      expect(kind.tag(ScanLabelLanguage.english), 'id-card');
    });

    test('an ID card known only by its number and its fields', () {
      // No card-naming word at all: recognised by the checksum agreeing.
      final kind = classifyScannedDocument(
        '姓名 李四\n'
        '性别 女 民族 汉\n'
        '住址 某市某区某街2号\n'
        '公民身份号码 11010519491231002X',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.idCard);
    });

    test('eighteen digits that do not checksum are nobody ID card', () {
      expect(
        classifyScannedDocument(
          '流水号 110105199001011234\n'
          '设备编号 998877665544332211\n'
          '备注 无',
        ),
        isNull,
      );
    });

    test('a driving licence', () {
      final kind = classifyScannedDocument(
        '中华人民共和国机动车驾驶证\n'
        '姓名 王五\n'
        '初次领证日期 2015-06-01\n'
        '准驾车型 C1\n'
        '有效期限 2021-06-01至2031-06-01',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.driverLicense);
      expect(kind.subject, '王五');
      expect(kind.tag(ScanLabelLanguage.chinese), '驾照');
    });

    test('a passport, by its machine-readable zone', () {
      final kind = classifyScannedDocument(
        '中华人民共和国护照\n'
        'POCHNZHANG<<SAN<<<<<<<<<<<<<<<<<<<<<<<\n'
        'E12345678CHN9001013M3001015<<<<<<<<<<06',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.passport);
      expect(kind.subject, 'Zhang San');
    });

    test('a business licence', () {
      final kind = classifyScannedDocument(
        '营业执照\n'
        '名称 北京示例科技有限公司\n'
        '统一社会信用代码 91110105MA01ABCD2X\n'
        '法定代表人 赵六\n'
        '经营范围 技术服务、技术咨询\n'
        '登记机关 北京市市场监督管理局',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.businessLicense);
      expect(kind.subject, '北京示例科技有限公司');
      expect(kind.tag(ScanLabelLanguage.chinese), '营业执照');
    });

    test('a business licence recognised by its credit code alone', () {
      final kind = classifyScannedDocument(
        '91110105MA01ABCD2X\n'
        '某某有限责任公司',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.businessLicense);
    });

    test('an invoice', () {
      final kind = classifyScannedDocument(
        '电子发票(普通发票)\n'
        '发票号码 12345678\n'
        '开票日期 2026年09月01日\n'
        '购买方 某某商行\n'
        '价税合计 ¥1,234.00',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.invoice);
      expect(kind.tag(ScanLabelLanguage.chinese), '发票');
    });

    test('a till receipt', () {
      final kind = classifyScannedDocument(
        '某某便利店\n'
        '收银：008 收银台：2\n'
        '商品明细\n'
        '合计 38.50\n'
        '实付 38.50 找零 0.00\n'
        '交易时间 2026-09-20 19:31\n'
        '谢谢惠顾，欢迎下次光临',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.posSlip);
      expect(kind.tag(ScanLabelLanguage.chinese), '小票');
    });

    test('a handwritten receipt stays a receipt, not a till slip', () {
      final kind = classifyScannedDocument(
        '收款收据\n'
        '今收到某某交来房租押金人民币贰仟元整\n'
        '收款人：某某\n'
        '2026年9月1日',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.receipt);
      expect(kind.tag(ScanLabelLanguage.chinese), '收据');
    });

    test('a business card', () {
      final kind = classifyScannedDocument(
        '某某科技有限公司\n'
        '孙七 总经理\n'
        '手机 13800000000\n'
        '邮箱 sunqi@example.com',
      );
      expect(kind, isNotNull);
      expect(kind!.kind, ScanDocumentKind.businessCard);
      expect(kind.subject, '某某科技有限公司');
    });

    test('a boarding pass', () {
      expect(
        classifyScannedDocument('登机牌 BOARDING PASS\n航班号 CA1234\n座位号 12A')
            ?.kind,
        ScanDocumentKind.boardingPass,
      );
    });

    test('plain prose is not a card', () {
      expect(
        classifyScannedDocument(
          '今天上午把窗帘洗了，顺便整理了书架。\n'
          '下午去邮局寄了包裹，回来的路上买了面包。\n'
          '晚上读了两页书就困了，比昨天早睡了一个钟头。',
        ),
        isNull,
      );
    });

    test('a long page merely mentioning an ID number is not one', () {
      expect(
        classifyScannedDocument(
          '设备清单\n' * 20 +
              '备注：出厂编号 110105199001011234，已核对 with Checksum',
        ),
        isNull,
      );
    });
  });

  group('outlineScannedText', () {
    final scannedAt = DateTime(2026, 9, 28);

    test('names a scan after its recognised type and holder', () {
      final draft = outlineScannedText(
        '中华人民共和国居民身份证\n'
        '姓名 张三\n'
        '性别 男 民族 汉\n'
        '公民身份号码 110105199001011234',
        scannedAt: scannedAt,
      );
      expect(draft, isNotNull);
      // The short type word, not the inscription the card prints across its
      // own face: the tag says which kind this is, so the title repeating the
      // full name would only make the list harder to scan.
      expect(draft!.title, '身份证 · 张三');
      expect(draft.tags, contains('身份证'));
      expect(draft.tags, contains('2026'));
    });

    test('falls back to the type and date when no name could be read', () {
      final draft = outlineScannedText(
        '营业执照\n'
        '统一社会信用代码 91110105MA01ABCD2X',
        scannedAt: scannedAt,
      );
      expect(draft, isNotNull);
      // The page's own headline said nothing the tag does not already say, so
      // the date is what makes this title distinguishable from the next one.
      expect(draft!.title, '营业执照 09-28');
      expect(draft.tags.first, '营业执照');
    });

    test('spells English labels when asked to', () {
      final draft = outlineScannedText(
        '中华人民共和国居民身份证\n'
        '姓名 张三\n'
        '公民身份号码 110105199001011234',
        scannedAt: scannedAt,
        fallbackPrefix: 'Scan',
        labels: ScanLabelLanguage.english,
      );
      expect(draft!.tags.first, 'id-card');
      // Same shape in either language: type word, then the holder.
      expect(draft.title, 'id-card · 张三');
    });

    test('a recognised slip is named by its type, not its letterhead', () {
      final draft = outlineScannedText(
        '某某科技有限公司 发票\n'
        '发票号码 12345678\n'
        '开票日期 2026年09月01日',
        scannedAt: scannedAt,
      );
      expect(draft, isNotNull);
      expect(draft!.title, '发票 09-28');
      expect(draft.tags.first, '发票');
    });

    test('a contract is still filed the way it always was', () {
      final draft = outlineScannedText(
        '房屋租赁合同\n'
        '甲方：某某 乙方：某某\n'
        '租期自2026年10月1日起至2027年9月30日止',
        scannedAt: scannedAt,
      );
      expect(draft, isNotNull);
      expect(draft!.title, '房屋租赁合同');
      expect(draft.tags, contains('合同'));
    });
  });
}
