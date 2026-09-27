import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_localization.dart';
import '../../core/top_toast.dart';
import '../../core/windows_adaptive_surface.dart';
import '../../data/models/personal_access_token.dart';
import '../../platform/widgets/platform_list_section.dart';
import '../../state/memos/memos_providers.dart';
import '../../state/settings/personal_access_token_repository_provider.dart';
import '../../state/system/session_provider.dart';
import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

enum _TokenExpiration { h8, d30, never }

extension on _TokenExpiration {
  String label(BuildContext context) => switch (this) {
    _TokenExpiration.h8 => '8h',
    _TokenExpiration.d30 => context.t.strings.legacy.msg_v_30_days,
    _TokenExpiration.never => context.t.strings.legacy.msg_never,
  };

  int get expiresInDays => switch (this) {
    // Memos API uses days. "8h" is approximated as 1 day.
    _TokenExpiration.h8 => 1,
    _TokenExpiration.d30 => 30,
    _TokenExpiration.never => 0,
  };
}

class ApiPluginsScreen extends ConsumerStatefulWidget {
  const ApiPluginsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  ConsumerState<ApiPluginsScreen> createState() => _ApiPluginsScreenState();
}

class _ApiPluginsScreenState extends ConsumerState<ApiPluginsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  var _expiration = _TokenExpiration.d30;
  var _creating = false;
  var _refreshing = false;
  String? _listError;
  List<PersonalAccessToken> _tokens = const [];
  Map<String, String> _tokenValues = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshTokens());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatError(Object e, BuildContext context) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = '';
      if (data is Map) {
        final m = data['message'] ?? data['error'] ?? data['detail'];
        if (m is String) message = m.trim();
      } else if (data is String) {
        message = data.trim();
      }
      final base = status == null
          ? context.t.strings.legacy.msg_network_request_failed
          : 'HTTP $status';
      if (message.isEmpty) return base;
      return '$base: $message';
    }
    return e.toString();
  }

  static String _formatDate(DateTime? time) {
    final dt = time?.toLocal();
    if (dt == null) return '-';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y.$m.$d';
  }

  static String? _last4(String value) {
    final s = value.trim();
    if (s.isEmpty) return null;
    if (s.length <= 4) return s;
    return s.substring(s.length - 4);
  }

  String _maskedTokenTail(PersonalAccessToken token) {
    final stored = _tokenValues[token.name];
    final tail = _last4(stored ?? token.id);
    if (tail == null || tail.isEmpty) {
      return context.t.strings.legacy.msg_token_tail_unknown;
    }
    return context.t.strings.legacy.msg_token_tail(tail: tail);
  }

  Future<void> _refreshTokens() async {
    if (_refreshing) return;
    final account = ref.read(appSessionProvider).valueOrNull?.currentAccount;
    if (account == null) return;

    setState(() {
      _refreshing = true;
      _listError = null;
    });

    final api = ref.read(memosApiProvider);
    final repo = ref.read(personalAccessTokenRepositoryProvider);
    try {
      final tokens = await api.listPersonalAccessTokens(
        userName: account.user.name,
      );
      final values = await repo.readAll(accountKey: account.key);
      if (!mounted) return;
      setState(() {
        _tokens = tokens;
        _tokenValues = values;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _listError = _formatError(e, context));
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _selectExpiration() async {
    if (_creating) return;
    final selected = await _showExpirationPicker(context);
    if (selected == null) return;
    if (!mounted) return;
    setState(() => _expiration = selected);
  }

  Future<_TokenExpiration?> _showExpirationPicker(BuildContext context) {
    Widget expirationContent(BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            for (final v in _TokenExpiration.values)
              ListTile(
                title: Text(v.label(context)),
                trailing: v == _expiration ? const Icon(Icons.check) : null,
                onTap: () => context.safePop(v),
              ),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    if (shouldUseWindowsAdaptiveSurface(context)) {
      return showWindowsAdaptiveSurface<_TokenExpiration>(
        context: context,
        kind: WindowsAdaptiveSurfaceKind.popover,
        maxWidth: 420,
        builder: expirationContent,
      );
    }
    return showModalBottomSheet<_TokenExpiration>(
      context: context,
      showDragHandle: true,
      builder: expirationContent,
    );
  }

  Future<void> _showTokenSheet(String token) {
    Widget tokenContent(BuildContext context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SettingsContentHeader(
                title: context.t.strings.legacy.msg_token_created,
              ),
              const SizedBox(height: 6),
              Text(
                context.t.strings.legacy.msg_shown_only_once_copy_keep_safe,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(token),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: token));
                        if (!context.mounted) return;
                        showTopToast(
                          context,
                          context.t.strings.legacy.msg_copied_clipboard,
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: Text(context.t.strings.legacy.msg_copy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.safePop(),
                      child: Text(context.t.strings.legacy.msg_done),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (shouldUseWindowsAdaptiveSurface(context)) {
      return showWindowsAdaptiveSurface<void>(
        context: context,
        maxWidth: 560,
        builder: tokenContent,
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: tokenContent,
    );
  }

  Future<void> _createToken() async {
    if (_creating) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final account = ref.read(appSessionProvider).valueOrNull?.currentAccount;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.strings.legacy.msg_not_signed)),
      );
      return;
    }

    setState(() => _creating = true);
    final api = ref.read(memosApiProvider);
    final repo = ref.read(personalAccessTokenRepositoryProvider);
    try {
      final response = await api.createPersonalAccessToken(
        userName: account.user.name,
        description: _descriptionController.text.trim(),
        expiresInDays: _expiration.expiresInDays,
      );
      final token = response.token;
      final tokenName = response.personalAccessToken.name.trim();
      if (tokenName.isNotEmpty) {
        await repo.saveTokenValue(
          accountKey: account.key,
          tokenName: tokenName,
          tokenValue: token,
        );
      }

      await Clipboard.setData(ClipboardData(text: token));
      if (!mounted) return;
      showTopToast(
        context,
        context.t.strings.legacy.msg_token_copied_clipboard,
      );
      await _showTokenSheet(token);
      await _refreshTokens();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t.strings.legacy.msg_create_failed(
              formatError_e_context: _formatError(e, context),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _copyExistingToken(PersonalAccessToken token) async {
    final value = _tokenValues[token.name]?.trim();
    if (value == null || value.isEmpty) {
      showTopToast(
        context,
        context.t.strings.legacy.msg_token_returned_only_once_cannot_fetched,
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showTopToast(context, context.t.strings.legacy.msg_copied_clipboard);
  }

  ({String label, Color bg, Color fg}) _statusBadge(PersonalAccessToken token) {
    final colorScheme = Theme.of(context).colorScheme;
    final expires = token.expiresAt;
    if (expires == null) {
      return (
        label: context.t.strings.legacy.msg_active,
        bg: colorScheme.primary.withValues(alpha: 0.14),
        fg: colorScheme.primary,
      );
    }

    final now = DateTime.now();
    if (expires.isBefore(now)) {
      return (
        label: context.t.strings.legacy.msg_expired,
        bg: colorScheme.error.withValues(alpha: 0.14),
        fg: colorScheme.error,
      );
    }

    if (expires.difference(now).inDays <= 7) {
      return (
        label: context.t.strings.legacy.msg_expiring,
        bg: colorScheme.tertiary.withValues(alpha: 0.16),
        fg: colorScheme.tertiary,
      );
    }

    return (
      label: context.t.strings.legacy.msg_active,
      bg: colorScheme.primary.withValues(alpha: 0.14),
      fg: colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_api_plugins),
      showBackButton: widget.showBackButton,
      onRefresh: _refreshTokens,
      children: [
        Form(
          key: _formKey,
          child: SettingsSection(
            header: Text(context.t.strings.legacy.msg_create_token),
            children: [
              _TokenDescriptionRow(
                controller: _descriptionController,
                enabled: !_creating,
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) {
                    return context.t.strings.legacy.msg_enter_token_name;
                  }
                  return null;
                },
              ),
              SettingsValueRow(
                label: context.t.strings.legacy.msg_expiration,
                value: _expiration.label(context),
                icon: Icons.keyboard_arrow_down_rounded,
                enabled: !_creating,
                onTap: _selectExpiration,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: SettingsAction(
            onPressed: _creating ? null : _createToken,
            icon: _creating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label: Text(context.t.strings.legacy.msg_create_token_2),
          ),
        ),
        SettingsSection(
          header: Text(context.t.strings.legacy.msg_existing_tokens),
          children: _tokenRows(context),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: SettingsRowDescription(
            context.t.strings.legacy.msg_keep_token_safe_not_share_api,
          ),
        ),
      ],
    );
  }

  List<Widget> _tokenRows(BuildContext context) {
    if (_listError != null) {
      return [
        PlatformListSectionRow(
          title: SettingsRowDescription(_listError!),
          trailing: TextButton(
            onPressed: _refreshTokens,
            child: Text(context.t.strings.legacy.msg_retry),
          ),
          denseOnDesktop: false,
        ),
      ];
    }
    if (_refreshing && _tokens.isEmpty) {
      return [
        const PlatformListSectionRow(
          title: Center(child: CircularProgressIndicator.adaptive()),
          denseOnDesktop: false,
        ),
      ];
    }
    if (_tokens.isEmpty) {
      return [
        SettingsInfoRow(
          description: context.t.strings.legacy.msg_no_tokens_yet,
        ),
      ];
    }
    return [
      for (final token in _tokens)
        _TokenItem(
          token: token,
          maskedTail: _maskedTokenTail(token),
          createdAtLabel: _formatDate(token.createdAt),
          badge: _statusBadge(token),
          onCopy: () => _copyExistingToken(token),
        ),
    ];
  }
}

class _TokenDescriptionRow extends StatelessWidget {
  const _TokenDescriptionRow({
    required this.controller,
    required this.enabled,
    required this.validator,
  });

  final TextEditingController controller;
  final bool enabled;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final tokens = settingsPageTokens(context);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: PlatformListSectionRow(
        title: SettingsRowTitle(context.t.strings.legacy.msg_token_name),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: TextFormField(
            controller: controller,
            enabled: enabled,
            style: TextStyle(
              color: tokens.textMain,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: context.t.strings.legacy.msg_enter_token_description,
              hintStyle: TextStyle(color: tokens.textMuted),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            validator: validator,
          ),
        ),
        denseOnDesktop: false,
      ),
    );
  }
}

class _TokenItem extends StatefulWidget {
  const _TokenItem({
    required this.token,
    required this.maskedTail,
    required this.createdAtLabel,
    required this.badge,
    required this.onCopy,
  });

  final PersonalAccessToken token;
  final String maskedTail;
  final String createdAtLabel;
  final ({String label, Color bg, Color fg}) badge;
  final VoidCallback onCopy;

  @override
  State<_TokenItem> createState() => _TokenItemState();
}

class _TokenItemState extends State<_TokenItem> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.badge.label;
    final badgeBg = widget.badge.bg;
    final badgeFg = widget.badge.fg;
    final tokens = settingsPageTokens(context);
    final colorScheme = Theme.of(context).colorScheme;

    final title = widget.token.description.trim().isEmpty
        ? context.t.strings.legacy.msg_unnamed_token
        : widget.token.description.trim();
    return PlatformListSectionRow(
      title: Row(
        children: [
          Expanded(child: SettingsRowTitle(title)),
          const SizedBox(width: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badgeFg,
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SettingsRowDescription(
              context.t.strings.legacy.msg_created(
                widget_createdAtLabel: widget.createdAtLabel,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.maskedTail,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: tokens.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
      trailing: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onCopy();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 140),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.copy_rounded,
                size: 18,
                color: tokens.textMuted,
              ),
            ),
          ),
        ),
      ),
      denseOnDesktop: false,
    );
  }
}
