import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

typedef DraftEdit = void Function(Countdown Function(Countdown));

/// The reminder chips shown up front; "Custom…" offers the rest.
const mainReminders = [0, 1440, 10080];

/// Details: name, date, time (with all day), repeats, remind me, count in.
class EditorDetails extends ConsumerWidget {
  const EditorDetails({
    super.key,
    required this.draft,
    required this.edit,
    required this.titleController,
    this.nameError = false,
    this.onDelete,
  });

  final Countdown draft;
  final DraftEdit edit;
  final TextEditingController titleController;
  final bool nameError;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = draft.reminders.where((r) => !mainReminders.contains(r));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Name'),
        const SizedBox(height: 8),
        TextField(
          controller: titleController,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16, color: AppColors.ink),
          decoration: InputDecoration(
            hintText: 'Birthday, trip, big day…',
            hintStyle: const TextStyle(color: AppColors.muted),
            filled: true,
            fillColor: AppColors.ground,
            errorText: nameError ? 'Give your countdown a name' : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.danger, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('When'),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.ground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _Row(
                label: 'Date',
                value: DateFormat('EEE, MMM d, y').format(draft.dateTime),
                onTap: () => _pickDate(context, ref),
              ),
              const _Divider(),
              _Row(
                label: 'Time',
                value: draft.allDay
                    ? ''
                    : DateFormat('h:mm a').format(draft.dateTime),
                onTap: draft.allDay ? null : () => _pickTime(context, ref),
                trailing: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      const Text(
                        'All day',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Transform.scale(
                        scale: 0.8,
                        child: AppSwitch(
                          label: 'All day',
                          value: draft.allDay,
                          onChanged: (v) {
                            feedback(ref, Sound.select);
                            edit((d) => d.copyWith(allDay: v));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const _Divider(),
              _Row(
                label: 'Repeats',
                value: draft.repeat.label,
                muted: draft.repeat == RepeatRule.none,
                onTap: () => _pickRepeat(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('Remind me'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final offset in mainReminders)
              ChoiceChipButton(
                label: reminderChoices[offset]!,
                selected: draft.reminders.contains(offset),
                onTap: () => _toggle(ref, offset),
              ),
            for (final offset in extra)
              ChoiceChipButton(
                label: reminderLabel(offset),
                selected: true,
                onTap: () => _toggle(ref, offset),
              ),
            ChoiceChipButton(
              label: 'Custom…',
              selected: false,
              onTap: () => _custom(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const SectionLabel('Count in'),
        const SizedBox(height: 10),
        PillSegmented<CountUnit>(
          values: CountUnit.values,
          selected: draft.unit,
          label: (u) => u.label,
          height: 34,
          fontSize: 13,
          onChanged: (u) {
            feedback(ref, Sound.select);
            edit((d) => d.copyWith(unit: u));
          },
        ),
        if (onDelete != null) ...[
          const SizedBox(height: 28),
          TextButton(
            onPressed: onDelete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text(
              'Delete countdown',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ],
    );
  }

  void _toggle(WidgetRef ref, int offset) {
    feedback(ref, Sound.select);
    edit((d) {
      final set = {...d.reminders};
      if (!set.remove(offset)) set.add(offset);
      return d.copyWith(reminders: set.toList()..sort());
    });
  }

  Future<void> _custom(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              const Text('Remind me', style: AppText.sheetTitle),
              const SizedBox(height: 12),
              for (final e in reminderChoices.entries)
                if (!mainReminders.contains(e.key))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.value),
                    trailing: draft.reminders.contains(e.key)
                        ? const Icon(Icons.check_rounded, color: AppColors.save)
                        : null,
                    onTap: () => Navigator.pop(context, e.key),
                  ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) _toggle(ref, picked);
  }

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    var value = draft.dateTime;
    final done = await _cupertinoSheet(
      context,
      'Date',
      CupertinoDatePicker(
        mode: CupertinoDatePickerMode.date,
        initialDateTime: draft.dateTime,
        minimumYear: 1900,
        maximumYear: 2200,
        onDateTimeChanged: (v) => value = v,
      ),
    );
    if (done) {
      edit(
        (d) => d.copyWith(
          dateTime: DateTime(
            value.year,
            value.month,
            value.day,
            d.dateTime.hour,
            d.dateTime.minute,
          ),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    var value = draft.dateTime;
    final done = await _cupertinoSheet(
      context,
      'Time',
      CupertinoDatePicker(
        mode: CupertinoDatePickerMode.time,
        initialDateTime: draft.dateTime,
        onDateTimeChanged: (v) => value = v,
      ),
    );
    if (done) {
      edit(
        (d) => d.copyWith(
          dateTime: DateTime(
            d.dateTime.year,
            d.dateTime.month,
            d.dateTime.day,
            value.hour,
            value.minute,
          ),
        ),
      );
    }
  }

  Future<void> _pickRepeat(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    final picked = await showModalBottomSheet<RepeatRule>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              const Text('Repeats', style: AppText.sheetTitle),
              const SizedBox(height: 12),
              for (final r in RepeatRule.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.label),
                  subtitle: r == RepeatRule.yearly
                      ? const Text('Birthdays, anniversaries, holidays')
                      : null,
                  trailing: draft.repeat == r
                      ? const Icon(Icons.check_rounded, color: AppColors.save)
                      : null,
                  onTap: () => Navigator.pop(context, r),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) edit((d) => d.copyWith(repeat: picked));
  }
}

Future<bool> _cupertinoSheet(
  BuildContext context,
  String title,
  Widget picker,
) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            Row(
              children: [
                Text(title, style: AppText.sheetTitle),
                const Spacer(),
                PillButton(
                  label: 'Done',
                  onTap: () => Navigator.pop(context, true),
                ),
              ],
            ),
            SizedBox(height: 216, child: picker),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
    this.muted = false,
  });

  final String label, value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool muted;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: muted ? AppColors.secondaryText : AppColors.primary,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 14),
    child: Divider(height: 1, thickness: 1, color: AppColors.track),
  );
}
