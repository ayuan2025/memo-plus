import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/rss/rss_feed_fetch_service.dart';
import '../../application/rss/rss_feed_parser.dart';
import '../../data/models/rss_feed_preview.dart';
import '../../data/repositories/rss_repository.dart';
import '../../i18n/strings.g.dart';
import '../../state/collections/collection_rss_providers.dart';

class CollectionRssSubscriptionSheet extends ConsumerStatefulWidget {
  const CollectionRssSubscriptionSheet({super.key, required this.collectionId});

  final String collectionId;

  @override
  ConsumerState<CollectionRssSubscriptionSheet> createState() =>
      _CollectionRssSubscriptionSheetState();
}

class _CollectionRssSubscriptionSheetState
    extends ConsumerState<CollectionRssSubscriptionSheet> {
  final TextEditingController _urlController = TextEditingController();
  bool _busy = false;
  String? _error;
  RssFeedPreview? _preview;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = context.t.strings.collections.rss.inputEmpty);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _preview = null;
    });
    try {
      final preview = await ref
          .read(rssFeedFetchServiceProvider)
          .previewUrl(url);
      if (!mounted) return;
      setState(() => _preview = preview);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = localizedRssError(context, error, previewing: true),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirm() async {
    var preview = _preview;
    if (preview == null) {
      await _loadPreview();
      preview = _preview;
      if (preview == null) return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(rssRepositoryProvider)
          .subscribeCollectionToPreview(
            collectionId: widget.collectionId,
            preview: preview,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              context.t.strings.collections.rss.subscribedTo(
                title: preview.displayTitle,
              ),
            ),
          ),
        );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = localizedRssError(context, error, previewing: false),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rssStrings = context.t.strings.collections.rss;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final preview = _preview;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    rssStrings.addFeed,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              enabled: !_busy,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loadPreview(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.rss_feed_rounded),
                labelText: rssStrings.inputLabel,
                border: OutlineInputBorder(),
              ),
            ),
            if (_error?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (preview != null) ...[
              const SizedBox(height: 16),
              RssFeedPreviewCard(preview: preview),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _loadPreview,
                    icon: const Icon(Icons.search_rounded),
                    label: Text(rssStrings.preview),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _confirm,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(rssStrings.subscribe),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String localizedRssError(
  BuildContext context,
  Object error, {
  required bool previewing,
}) {
  final rssStrings = context.t.strings.collections.rss;
  if (error is RssFeedDiscoveryException) {
    return switch (error.failure) {
      RssFeedDiscoveryFailure.emptyInput => rssStrings.inputEmpty,
      RssFeedDiscoveryFailure.invalidUrl => rssStrings.invalidInput,
      RssFeedDiscoveryFailure.noFeedDiscovered => rssStrings.noFeedDiscovered,
    };
  }
  if (error is RssFeedParseException) {
    return rssStrings.noFeedDiscovered;
  }
  return previewing ? rssStrings.previewFailed : rssStrings.subscribeFailed;
}

class RssFeedPreviewCard extends StatelessWidget {
  const RssFeedPreviewCard({super.key, required this.preview});

  final RssFeedPreview preview;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.displayTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            preview.siteUrl.trim().isNotEmpty
                ? preview.siteUrl
                : preview.feedUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted),
          ),
          if (preview.description.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              preview.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (preview.articles.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...preview.articles
                .take(3)
                .map(
                  (article) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.article_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            article.title.trim().isEmpty
                                ? article.link
                                : article.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
