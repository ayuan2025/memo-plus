import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/memo_collection.dart';

void main() {
  test('MemoCollection JSON roundtrip preserves nested settings', () {
    final collection = MemoCollection(
      id: 'col-1',
      title: 'Reading',
      description: 'Long form notes',
      type: MemoCollectionType.smart,
      iconKey: 'book',
      accentColorHex: '#4CB782',
      rules: const CollectionRuleSet(
        tagPaths: <String>['reading', 'projects/books'],
        tagMatchMode: CollectionTagMatchMode.all,
        includeDescendants: true,
        visibility: CollectionVisibilityScope.privateOnly,
        dateRule: CollectionDateRule(
          type: CollectionDateRuleType.lastDays,
          lastDays: 30,
        ),
        attachmentRule: CollectionAttachmentRule.imagesOnly,
        pinnedOnly: true,
      ),
      cover: const CollectionCoverSpec(
        mode: CollectionCoverMode.icon,
        iconKey: 'book',
      ),
      view: const CollectionViewPreferences(
        defaultLayout: CollectionLayoutMode.timeline,
        sectionMode: CollectionSectionMode.month,
        sortMode: CollectionSortMode.updateTimeDesc,
        showStats: false,
        readingExperience: CollectionReadingExperience.articleFlow,
        articleFlowDisplay: CollectionArticleFlowDisplaySettings(
          showExcerpt: false,
          showThumbnail: true,
          showFeedIcon: false,
          density: CollectionArticleFlowDensity.compact,
          autoHideToolbar: true,
        ),
        rssRefresh: CollectionRssRefreshPreferences(
          enabled: false,
          intervalMinutes: 120,
        ),
      ),
      pinned: true,
      archived: false,
      hideWhenEmpty: true,
      sortOrder: 4,
      createdTime: DateTime(2025, 1, 1, 8),
      updatedTime: DateTime(2025, 1, 2, 9),
    );

    final decoded = MemoCollection.fromJson(collection.toJson());

    expect(decoded.id, collection.id);
    expect(decoded.title, collection.title);
    expect(decoded.iconKey, collection.iconKey);
    expect(decoded.accentColorHex, collection.accentColorHex);
    expect(
      decoded.rules.normalizedTagPaths,
      collection.rules.normalizedTagPaths,
    );
    expect(decoded.rules.tagMatchMode, collection.rules.tagMatchMode);
    expect(decoded.rules.visibility, collection.rules.visibility);
    expect(decoded.rules.dateRule.type, collection.rules.dateRule.type);
    expect(decoded.cover.mode, collection.cover.mode);
    expect(decoded.view.defaultLayout, collection.view.defaultLayout);
    expect(decoded.view.sectionMode, collection.view.sectionMode);
    expect(decoded.view.sortMode, collection.view.sortMode);
    expect(decoded.view.rssRefresh.enabled, isFalse);
    expect(decoded.view.rssRefresh.intervalMinutes, 120);
    expect(decoded.pinned, isTrue);
    expect(decoded.hideWhenEmpty, isTrue);
    expect(decoded.sortOrder, 4);
  });

  test('RSS collection JSON and DB roundtrip preserve type defaults', () {
    final collection = MemoCollection.createRss(
      id: 'rss-1',
      title: 'RSS Reading',
      createdTime: DateTime(2026, 5, 1, 8),
      updatedTime: DateTime(2026, 5, 1, 9),
    );

    final decoded = MemoCollection.fromJson(collection.toJson());

    expect(decoded.type, MemoCollectionType.rss);
    expect(decoded.iconKey, MemoCollection.rssIconKey);
    expect(decoded.cover.mode, CollectionCoverMode.icon);
    expect(decoded.cover.iconKey, MemoCollection.rssIconKey);
    expect(decoded.rules.hasAnyConstraint, isFalse);
    expect(decoded.view.sortMode, CollectionSortMode.displayTimeDesc);
    expect(decoded.view.rssRefresh, CollectionRssRefreshPreferences.defaults);

    final fromDb = MemoCollection.fromDb(<String, Object?>{
      'id': decoded.id,
      'title': decoded.title,
      'description': decoded.description,
      'type': 'rss',
      'icon_key': decoded.iconKey,
      'accent_color_hex': null,
      'rules_json': '{}',
      'cover_json': '{"mode":"icon","iconKey":"rss_feed"}',
      'view_json': '{"sortMode":"displayTimeDesc"}',
      'pinned': 0,
      'archived': 0,
      'hide_when_empty': 0,
      'sort_order': 0,
      'created_time': 1777622400,
      'updated_time': 1777626000,
    });

    expect(fromDb.type, MemoCollectionType.rss);
    expect(fromDb.isRss, isTrue);
  });
}
