import 'package:countdowns/constants.dart';
import 'package:countdowns/models/app_icons.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/utilities/sample_data.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

final packageInfoProvider = FutureProvider((ref) => PackageInfo.fromPlatform());

bool get _showAppIcon => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      MediaQuery.sizeOf(context).width >= 900
      ? const _TabletSettings()
      : Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        button: true,
                        label: 'Back to Countdowns',
                        child: GestureDetector(
                          onTap: () {
                            feedback(ref);
                            context.pop();
                          },
                          child: const SizedBox(
                            height: 44,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chevron_left_rounded,
                                  color: AppColors.primary,
                                ),
                                Text(
                                  'Countdowns',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: MarkedTitle(
                          'Settings',
                          style: AppText.largeTitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(child: SettingsList()),
              ],
            ),
          ),
        );
}

/// Every setting, grouped. Shared by the phone screen and the iPad
/// sidebar layout.
class SettingsList extends ConsumerWidget {
  const SettingsList({super.key, this.section});

  /// On iPad, only this section is shown.
  final SettingsSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = section == null
        ? SettingsSection.values
        : [
            section!,
            if (section == SettingsSection.support) SettingsSection.danger,
          ];
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        40 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        for (final s in sections) ...[
          if (s == SettingsSection.appearance && !_showAppIcon)
            const SizedBox.shrink()
          else ...[
            _section(context, ref, s),
            const SizedBox(height: 22),
          ],
        ],
      ],
    );
  }

  Widget _section(BuildContext context, WidgetRef ref, SettingsSection s) =>
      switch (s) {
        SettingsSection.appearance => const _Appearance(),
        SettingsSection.countdowns => const _Countdowns(),
        SettingsSection.notifications => const _Notifications(),
        SettingsSection.support => const _Support(),
        SettingsSection.danger => const _Danger(),
      };
}

enum SettingsSection {
  appearance('Appearance', Icons.palette_outlined),
  countdowns('Countdowns', Icons.hourglass_empty_rounded),
  notifications('Notifications and feel', Icons.notifications_none_rounded),
  support('Support and about', Icons.info_outline_rounded),
  danger('Delete', Icons.delete_outline_rounded);

  const SettingsSection(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
    child: SectionLabel(text),
  );
}

/// A coloured icon tile, as on the canvas.
class _Badge extends StatelessWidget {
  const _Badge(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, size: 17, color: AppColors.ink),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    this.badge,
    this.trailing,
    this.value,
    this.onTap,
  });

  final String label;
  final Widget? badge;
  final Widget? trailing;
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            if (badge != null) ...[badge!, const SizedBox(width: 12)],
            Expanded(child: Text(label, style: AppText.body)),
            if (value != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 190),
                child: Text(
                  value!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            if (trailing != null)
              trailing!
            else if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.secondaryText,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Line extends StatelessWidget {
  const _Line();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 58),
    child: Divider(height: 1, thickness: 1, color: AppColors.divider),
  );
}

class _Appearance extends ConsumerWidget {
  const _Appearance();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final iconName = ref.watch(localSettingsProvider.select((s) => s.iconName));
    final icon = appIconFor(iconName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Appearance'),
        GroupCard(
          children: [
            _Row(
              label: 'App icon',
              badge: ClipRRect(
                borderRadius: BorderRadius.circular(0.2237 * 30),
                child: Image.asset(icon.assetPath, width: 30, height: 30),
              ),
              value: icon.label,
              onTap: () {
                feedback(ref);
                context.pushNamed(AppRoutes.appIcon);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _Countdowns extends ConsumerWidget {
  const _Countdowns();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localSettingsProvider);
    final controller = ref.read(localSettingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Countdowns'),
        GroupCard(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      _Badge(Icons.timer_outlined, sun),
                      SizedBox(width: 12),
                      Text('Count in by default', style: AppText.body),
                    ],
                  ),
                  const SizedBox(height: 10),
                  PillSegmented<CountUnit>(
                    values: CountUnit.values,
                    selected: settings.defaultUnit,
                    label: (u) => u.label,
                    height: 34,
                    fontSize: 13,
                    onChanged: (u) {
                      feedback(ref, Sound.select, false);
                      controller.setDefaultUnit(u);
                    },
                  ),
                ],
              ),
            ),
            const _Line(),
            _Row(
              label: 'Keep finished in Done',
              badge: const _Badge(Icons.check_rounded, lime),
              trailing: AppSwitch(
                label: 'Keep finished in Done',
                value: settings.keepDone,
                onChanged: (v) {
                  feedback(ref, Sound.select);
                  controller.setKeepDone(v);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Notifications extends ConsumerWidget {
  const _Notifications();

  Future<void> _setNotify(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    feedback(ref, Sound.select);
    final controller = ref.read(localSettingsProvider.notifier);
    final events = ref.read(eventsControllerProvider);
    if (!value) {
      await controller.setNotify(false);
      await events.rescheduleNotifications();
      return;
    }
    final granted = await ref.read(notificationsProvider).requestPermission();
    if (!context.mounted) return;
    if (granted) {
      await controller.setNotify(true);
      await events.rescheduleNotifications();
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications are off'),
        content: const Text(
          'Turn on notifications for Countdowns in Settings to get reminders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not now'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localSettingsProvider);
    final controller = ref.read(localSettingsProvider.notifier);
    final supported = ref.watch(notificationsProvider).supported;
    final defaults = [...settings.defaultReminders]
      ..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Notifications and feel'),
        GroupCard(
          children: [
            if (supported) ...[
              _Row(
                label: 'Notify when one ends',
                badge: const _Badge(
                  Icons.notifications_none_rounded,
                  bubblegum,
                ),
                trailing: AppSwitch(
                  label: 'Notify when one ends',
                  value: settings.notify,
                  onChanged: (v) => _setNotify(context, ref, v),
                ),
              ),
              const _Line(),
            ],
            _Row(
              label: 'Sound effects',
              badge: const _Badge(Icons.volume_up_outlined, sky),
              trailing: AppSwitch(
                label: 'Sound effects',
                value: settings.soundEffects,
                onChanged: (v) {
                  controller.setSoundEffectsMode(v);
                  feedback(ref, Sound.select);
                },
              ),
            ),
            const _Line(),
            _Row(
              label: 'Haptic feedback',
              badge: const _Badge(Icons.vibration_rounded, lilac),
              trailing: AppSwitch(
                label: 'Haptic feedback',
                value: settings.hapticFeedback,
                onChanged: (v) {
                  controller.setHapticFeedbackMode(v);
                  feedback(ref, Sound.select);
                },
              ),
            ),
            const _Line(),
            _Row(
              label: 'Default reminders',
              badge: const _Badge(Icons.alarm_rounded, peach),
              value: defaults.isEmpty
                  ? 'None'
                  : defaults.map(_short).join(', '),
              onTap: () => _editDefaults(context, ref),
            ),
          ],
        ),
      ],
    );
  }

  static String _short(int offset) => switch (offset) {
    0 => 'Day of',
    1440 => 'Day before',
    10080 => 'Week before',
    _ => reminderLabel(offset).replaceAll(' before', ''),
  };

  Future<void> _editDefaults(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final selected = ref.watch(
            localSettingsProvider.select((s) => s.defaultReminders),
          );
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Default reminders',
                          style: AppText.sheetTitle,
                        ),
                      ),
                      PillButton(
                        label: 'Done',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'New countdowns start with these.',
                    style: AppText.secondary,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in reminderChoices.entries)
                        ChoiceChipButton(
                          label: e.value,
                          selected: selected.contains(e.key),
                          onTap: () {
                            final next = {...selected};
                            if (!next.remove(e.key)) next.add(e.key);
                            ref
                                .read(localSettingsProvider.notifier)
                                .setDefaultReminders(next.toList());
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Support extends ConsumerWidget {
  const _Support();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).asData?.value;
    void open(String url) => launchUrl(Uri.parse(url));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Support and about'),
        GroupCard(
          children: [
            _Row(
              label: 'Rate Countdowns',
              onTap: () => InAppReview.instance.openStoreListing(
                appStoreId: '1603744166',
              ),
            ),
            const _Line(),
            _Row(
              label: 'Contact',
              value: 'countdowns@chrisstayte.com',
              onTap: () async {
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'countdowns@chrisstayte.com',
                  query:
                      'subject=App Feedback&body=\n\n\nApp Version ${info?.version ?? 'Unknown'}',
                );
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const _Line(),
            _Row(
              label: 'Privacy Policy',
              onTap: () => open('https://chrisstayte.app/countdowns/privacy/'),
            ),
            const _Line(),
            _Row(
              label: 'Terms of Use',
              onTap: () => open('https://chrisstayte.app/countdowns/terms/'),
            ),
            const _Line(),
            _Row(
              label: 'Source code',
              onTap: () => open('https://github.com/chrisstayte/countdowns'),
            ),
            const _Line(),
            _Row(
              label: '@chrisstayte',
              onTap: () => open('https://x.com/chrisstayte'),
            ),
            const _Line(),
            _Row(
              label: 'About',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Countdowns',
                applicationVersion: info?.version,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Danger extends ConsumerWidget {
  const _Danger();

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    feedback(ref);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all countdowns?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep them'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    feedback(ref, Sound.trash);
    await ref.read(eventsControllerProvider).deleteAllEvents();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider).asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          child: GestureDetector(
            onTap: () => _deleteAll(context, ref),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Text(
                'Delete all countdowns',
                style: TextStyle(
                  color: AppColors.danger,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Countdowns ${info?.version ?? ''} · Made by Chris Stayte',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.secondaryText),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 22),
          const _Heading('Debug'),
          GroupCard(
            children: [
              _Row(
                label: 'Load sample countdowns',
                onTap: () async {
                  for (final c in sampleCountdowns(DateTime.now())) {
                    await ref.read(eventsControllerProvider).save(c);
                  }
                },
              ),
              const _Line(),
              _Row(
                label: 'Print pending notifications',
                onTap: () async {
                  final List<PendingNotificationRequest> pending = await ref
                      .read(notificationsProvider)
                      .plugin
                      .pendingNotificationRequests();
                  for (final p in pending) {
                    debugPrint('${p.id} ${p.title} ${p.body}');
                  }
                },
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// iPad: a sidebar of categories with a roomy detail pane.
class _TabletSettings extends ConsumerStatefulWidget {
  const _TabletSettings();

  @override
  ConsumerState<_TabletSettings> createState() => _TabletSettingsState();
}

class _TabletSettingsState extends ConsumerState<_TabletSettings> {
  late SettingsSection _section = _showAppIcon
      ? SettingsSection.appearance
      : SettingsSection.countdowns;

  static const _colors = {
    SettingsSection.appearance: mint,
    SettingsSection.countdowns: sun,
    SettingsSection.notifications: bubblegum,
    SettingsSection.support: sky,
  };

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(packageInfoProvider).asData?.value;
    final sections = [
      for (final s in SettingsSection.values)
        if (s != SettingsSection.danger &&
            (s != SettingsSection.appearance || _showAppIcon))
          s,
    ];
    return Scaffold(
      backgroundColor: AppColors.wash,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 300,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextAction(
                        '‹ Countdowns',
                        onTap: () => context.pop(),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(10, 4, 10, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: MarkedTitle(
                          'Settings',
                          style: AppText.largeTitle,
                        ),
                      ),
                    ),
                    for (final s in sections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Semantics(
                          button: true,
                          selected: s == _section,
                          child: GestureDetector(
                            onTap: () {
                              feedback(ref, Sound.select);
                              setState(() => _section = s);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: s == _section
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  _Badge(s.icon, _colors[s]!),
                                  const SizedBox(width: 12),
                                  Text(
                                    s.label,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Countdowns ${info?.version ?? ''}',
                        style: AppText.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.ground,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: SettingsList(
                        key: ValueKey(_section),
                        section: _section,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
