import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Debug: every reminder the app plans, when it goes off, and whether the
/// phone really has it pending.
Future<void> showScheduledReminders(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => const _ScheduledReminders(),
    );

typedef _Report = ({
  List<NotificationRequest> plan,
  Set<int> pending,
  String zone,
  bool? exact,
});

final _reportProvider = FutureProvider.autoDispose<_Report>((ref) async {
  final notifications = ref.read(notificationsProvider);
  return (
    plan: await ref.read(eventsControllerProvider).plannedNotifications(),
    pending: await notifications.pendingIds(),
    zone: (await notifications.localZone()).name,
    exact: await notifications.exactAlarmsAllowed(),
  );
});

class _ScheduledReminders extends ConsumerWidget {
  const _ScheduledReminders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(_reportProvider);
    final notify = ref.watch(localSettingsProvider.select((s) => s.notify));
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Scheduled reminders',
                      style: AppText.sheetTitle,
                    ),
                  ),
                  PillButton(
                    label: 'Reschedule',
                    onTap: () async {
                      await ref
                          .read(eventsControllerProvider)
                          .rescheduleNotifications();
                      ref.invalidate(_reportProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: switch (report) {
                  AsyncData(:final value) => _list(value, notify),
                  AsyncError(:final error) => Text(
                    '$error',
                    style: AppText.body,
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(_Report r, bool notify) {
    final planned = r.plan.map((p) => p.id).toSet();
    final stray = r.pending.difference(planned).toList()..sort();
    final scheduled = r.plan.where((p) => r.pending.contains(p.id)).length;
    final format = DateFormat('EEE d MMM y, h:mm a');
    return ListView(
      children: [
        Text(
          [
            'Notifications ${notify ? 'on' : 'off'} · ${r.zone}',
            if (r.exact != null)
              r.exact!
                  ? 'Exact alarms allowed'
                  : 'Exact alarms off: up to an hour late',
            '$scheduled of ${r.plan.length} planned are pending',
            if (r.plan.length == maxPendingNotifications)
              'Only the $maxPendingNotifications soonest are planned',
          ].join('\n'),
          style: AppText.secondary,
        ),
        const SizedBox(height: 14),
        if (r.plan.isEmpty && stray.isEmpty)
          const Text('No reminders to schedule.', style: AppText.body),
        for (final p in r.plan)
          _Item(
            title: p.title,
            detail: [
              format.format(p.when),
              p.body,
              if (p.match != null) 'every year',
            ].join(' · '),
            ok: r.pending.contains(p.id),
            status: r.pending.contains(p.id) ? 'Pending' : 'Not pending',
          ),
        for (final id in stray)
          _Item(
            title: 'Reminder $id',
            detail: 'Pending but no longer planned',
            ok: false,
            status: 'Stray',
          ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.title,
    required this.detail,
    required this.ok,
    required this.status,
  });

  final String title, detail, status;
  final bool ok;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(detail, style: AppText.secondary),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          status,
          style: AppText.secondary.copyWith(
            color: ok ? AppColors.ink : AppColors.danger,
          ),
        ),
      ],
    ),
  );
}
