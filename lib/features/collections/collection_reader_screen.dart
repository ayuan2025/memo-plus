import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/collection_readable_item.dart';
import '../../data/models/memo_collection.dart';
import '../../i18n/strings.g.dart';
import '../../platform/widgets/platform_action_sheet.dart';
import '../../platform/widgets/platform_page.dart';
import '../../state/collections/collections_provider.dart';
import 'collection_editor_screen.dart';
import 'collection_reader_shell.dart';
import 'collection_rss_subscription_sheet.dart';

class CollectionReaderScreen extends ConsumerWidget {
  const CollectionReaderScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectionsStrings = context.t.strings.collections;
    final collectionAsync = ref.watch(collectionByIdProvider(collectionId));
    final itemsAsync = ref.watch(
      collectionResolvedReadableItemsProvider(collectionId),
    );
    if (collectionAsync.isLoading || itemsAsync.isLoading) {
      return const PlatformPage(
        title: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (collectionAsync.hasError) {
      return PlatformPage(
        body: Center(child: Text('${collectionAsync.error}')),
      );
    }
    if (itemsAsync.hasError) {
      return PlatformPage(body: Center(child: Text('${itemsAsync.error}')));
    }
    final collection =
        collectionAsync.valueOrNull ??
        MemoCollection.createSmart(id: '', title: '');
    final items = itemsAsync.valueOrNull ?? const <CollectionReadableItem>[];
    if (items.isEmpty) {
      final title = collection.title.trim().isEmpty
          ? collectionsStrings.collection
          : collection.title;
      final isRssCollection = collection.type == MemoCollectionType.rss;
      return PlatformPage(
        title: Text(title),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRssCollection
                      ? collectionsStrings.rss.noArticles
                      : collectionsStrings.emptyManualDetail,
                  textAlign: TextAlign.center,
                ),
                if (isRssCollection) ...[
                  const SizedBox(height: 8),
                  Text(
                    collectionsStrings.rss.noArticlesDescription,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 16),
                if (isRssCollection)
                  FilledButton.icon(
                    onPressed: () => showPlatformActionSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (_) => CollectionRssSubscriptionSheet(
                        collectionId: collectionId,
                      ),
                    ),
                    icon: const Icon(Icons.rss_feed_rounded),
                    label: Text(collectionsStrings.rss.addFeed),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => openCollectionEditor(
                      context,
                      initialCollection: collection,
                    ),
                    icon: const Icon(Icons.edit_rounded),
                    label: Text(collectionsStrings.editCollection),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return CollectionReaderShell(
      collectionId: collectionId,
      collectionTitle: collection.title.trim().isEmpty
          ? collectionsStrings.collection
          : collection.title,
      items: items,
    );
  }
}
