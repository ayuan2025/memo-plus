import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/memoflow_palette.dart';
import '../../data/models/local_memo.dart';
import '../../i18n/strings.g.dart';

final DateFormat _memoTimeAdjustmentFormatter = DateFormat('yyyy-MM-dd HH:mm');
final DateFormat _memoTimeAdjustmentDateFormatter = DateFormat('yyyy-MM-dd');

const memoTimeAdjustmentSheetKey = ValueKey<String>(
  'memo-time-adjustment-sheet',
);
const memoTimeAdjustmentDateButtonKey = ValueKey<String>(
  'memo-time-adjustment-date-button',
);
const memoTimeAdjustmentTimeButtonKey = ValueKey<String>(
  'memo-time-adjustment-time-button',
);
const memoTimeAdjustmentSaveButtonKey = ValueKey<String>(
  'memo-time-adjustment-save-button',
);
const memoTimeAdjustmentCancelButtonKey = ValueKey<String>(
  'memo-time-adjustment-cancel-button',
);

String memoTimeAdjustmentActionLabel(BuildContext context) {
  return context.t.strings.memoTimeAdjustment.action;
}

String memoTimeAdjustmentSavedLabel(BuildContext context) {
  return context.t.strings.memoTimeAdjustment.saved;
}

Future<DateTime?> showMemoTimeAdjustmentSheet({
  required BuildContext context,
  required LocalMemo memo,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _MemoTimeAdjustmentSheet(memo: memo),
  );
}

class _MemoTimeAdjustmentSheet extends StatefulWidget {
  const _MemoTimeAdjustmentSheet({required this.memo});

  final LocalMemo memo;

  @override
  State<_MemoTimeAdjustmentSheet> createState() =>
      _MemoTimeAdjustmentSheetState();
}

class _MemoTimeAdjustmentSheetState extends State<_MemoTimeAdjustmentSheet> {
  late DateTime _selectedTime;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.memo.effectiveDisplayTime;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTime,
      firstDate: DateTime(1970),
      lastDate: DateTime(DateTime.now().year + 20, 12, 31),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _selectedTime = DateTime(
        _selectedTime.year,
        _selectedTime.month,
        _selectedTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  void _save() {
    Navigator.of(context).pop(_selectedTime);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMain = isDark
        ? MemoFlowPalette.textDark
        : MemoFlowPalette.textLight;
    final textMuted = textMain.withValues(alpha: isDark ? 0.58 : 0.66);
    final border = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;
    final insets = MediaQuery.viewInsetsOf(context);

    Widget valueButton({
      required Key key,
      required IconData icon,
      required String label,
      required String value,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton(
        key: key,
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: MemoFlowPalette.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      key: memoTimeAdjustmentSheetKey,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            memoTimeAdjustmentActionLabel(context),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.t.strings.memoTimeAdjustment.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: textMuted),
          ),
          const SizedBox(height: 16),
          valueButton(
            key: memoTimeAdjustmentDateButtonKey,
            icon: Icons.event_outlined,
            label: context.t.strings.memoTimeAdjustment.dateField,
            value: _memoTimeAdjustmentDateFormatter.format(_selectedTime),
            onPressed: _pickDate,
          ),
          const SizedBox(height: 10),
          valueButton(
            key: memoTimeAdjustmentTimeButtonKey,
            icon: Icons.schedule_outlined,
            label: context.t.strings.memoTimeAdjustment.timeField,
            value: DateFormat.Hm().format(_selectedTime),
            onPressed: _pickTime,
          ),
          const SizedBox(height: 10),
          Text(
            context.t.strings.memoTimeAdjustment.selectedCreationTime(
              value: _memoTimeAdjustmentFormatter.format(_selectedTime),
            ),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: textMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  key: memoTimeAdjustmentCancelButtonKey,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.t.strings.legacy.msg_cancel_2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  key: memoTimeAdjustmentSaveButtonKey,
                  onPressed: _save,
                  child: Text(context.t.strings.legacy.msg_save),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
