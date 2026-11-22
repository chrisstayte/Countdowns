import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/models/app_icons.dart';
import 'package:countdowns/constants.dart';
import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';

import 'package:countdowns/screens/settings/widget/settings_container.dart';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final _packageInfoProvider = FutureProvider(
  (ref) => PackageInfo.fromPlatform(),
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(localSettingsProvider);
    final packageInfo = ref.watch(_packageInfoProvider).asData?.value;
    final notifications = ref.watch(notificationsProvider);
    final flutterLocalNotificationsPlugin = notifications.plugin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            var settings = ref.read(localSettingsProvider);
            if (settings.hapticFeedback) {
              HapticFeedback.lightImpact();
            }
            if (settings.soundEffects) {
              AudioPlayer().play(
                AssetSource('sounds/tap.mp3'),
                ctx: AudioContext(
                  iOS: AudioContextIOS(
                    category: AVAudioSessionCategory.ambient,
                  ),
                ),
                mode: PlayerMode.lowLatency,
              );
            }
            context.pop();
          },
        ),
      ),
      body: ListView(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        padding: const EdgeInsets.only(
          top: 15.0,
          left: 15.0,
          right: 15.0,
          bottom: 85.0,
        ),
        children: [
          if (kDebugMode && notifications.supported)
            SettingsContainer(
              title: 'Debug',
              children: [
                ListTile(
                  title: const Text('Send Notification'),
                  trailing: const Icon(Icons.notification_add),
                  onTap: () async {
                    await Future.delayed(const Duration(seconds: 2), () {
                      flutterLocalNotificationsPlugin.cancelAll();
                    });
                    flutterLocalNotificationsPlugin.show(
                      id: 0,
                      title: 'Countdowns',
                      body: 'This is a test notification',
                      notificationDetails: NotificationDetails(
                        android: AndroidNotificationDetails(
                          'test',
                          'test',
                          importance: Importance.max,
                          priority: Priority.high,
                          showWhen: false,
                          enableVibration: true,
                          playSound: true,
                          enableLights: true,
                          color: Global.colors.primaryColor,
                          ledColor: Colors.red,
                          ledOnMs: 1000,
                          ledOffMs: 500,
                        ),
                        iOS: const DarwinNotificationDetails(
                          presentAlert: false,
                          presentBadge: false,
                          presentSound: false,
                          presentBanner: false,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text("Print Current Time Zone"),
                  onTap: () async {
                    final timeZone = await FlutterTimezone.getLocalTimezone();
                    debugPrint(timeZone.identifier);
                  },
                ),
                ListTile(
                  title: const Text("Print Scheduled Events"),
                  onTap: () async {
                    final List<PendingNotificationRequest>
                    pendingNotificationRequests =
                        await flutterLocalNotificationsPlugin
                            .pendingNotificationRequests();

                    for (var element in pendingNotificationRequests) {
                      debugPrint(element.id.toString());
                    }
                  },
                ),
              ],
            ),
          SettingsContainer(
            title: 'events',
            children: [
              ListTile(
                leading: const Icon(Icons.sort_rounded),
                title: const Text("Sort"),
                trailing: FractionallySizedBox(
                  widthFactor: 0.6,
                  child: DropdownButton<SortingMethod>(
                    isExpanded: true,
                    alignment: Alignment.centerRight,
                    value: settings.sortingMethod,
                    underline: Container(),
                    items: SortingMethod.values
                        .map(
                          (sortingMethod) => DropdownMenuItem(
                            alignment: Alignment.centerRight,
                            value: sortingMethod,
                            child: Text(
                              sortingMethod.nameReadable,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      ref
                          .read(localSettingsProvider.notifier)
                          .setSortingMethod(value!);
                    },
                  ),
                ),
              ),
            ],
          ),
          SettingsContainer(
            title: 'Display',
            children: [
              if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)
                ListTile(
                  leading: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0.2237 * 28),
                    ),
                    child: Image.asset(
                      appIconFor(settings.iconName).assetPath,
                      height: 28,
                    ),
                  ),
                  title: const Text('App Icon'),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () => context.pushNamed(AppRoutes.appIcon),
                ),
            ],
          ),
          SettingsContainer(
            title: 'sounds and haptics',
            children: [
              ListTile(
                leading: const Icon(Icons.volume_up_rounded),
                title: const Text('Sounds Effects'),
                trailing: Switch.adaptive(
                  value: settings.soundEffects,
                  onChanged: (value) {
                    ref
                        .read(localSettingsProvider.notifier)
                        .setSoundEffectsMode(value);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.vibration_rounded),
                title: const Text('Haptic Feedback'),
                trailing: Switch.adaptive(
                  value: settings.hapticFeedback,
                  onChanged: (value) {
                    ref
                        .read(localSettingsProvider.notifier)
                        .setHapticFeedbackMode(value);
                  },
                ),
              ),
            ],
          ),
          if (notifications.supported)
            SettingsContainer(
              title: 'Notifications',
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('When Event Ends'),
                  trailing: Switch.adaptive(
                    value: settings.notify,
                    onChanged: (value) async {
                      // If the user is requesting to turn them off, simply do so.
                      if (!value) {
                        ref
                            .read(localSettingsProvider.notifier)
                            .setNotify(value);
                        await flutterLocalNotificationsPlugin.cancelAll();
                        return;
                      }

                      AlertDialog goToSettingsAlertDialog = AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: Global.styles.containerCornerRadius,
                        ),
                        title: const Text('Permissions Required'),
                        content: const Text('Please enable notifications.'),
                        actions: [
                          OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Nevermind'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              openAppSettings();
                              context.pop();
                              return;
                            },
                            child: const Text('Take Me There'),
                          ),
                        ],
                      );

                      final granted = await notifications.requestPermission();
                      if (!context.mounted) return;
                      if (granted) {
                                                await ref
                            .read(localSettingsProvider.notifier)
                            .setNotify(true);
                        await ref
                            .read(eventsControllerProvider)
                            .rescheduleNotifications();
                      } else {
                        await showDialog(
                          context: context,
                          builder: (_) => goToSettingsAlertDialog,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          SettingsContainer(
            title: 'support',
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_rounded),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => launchUrl(
                  Uri.parse('https://chrisstayte.app/countdowns/privacy/'),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.article_rounded),
                title: const Text('Terms of Use'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => launchUrl(
                  Uri.parse('https://chrisstayte.app/countdowns/terms/'),
                ),
              ),
              const AboutListTile(
                icon: Icon(Icons.info_outline_rounded),
                applicationName: 'Countdowns',
                applicationIcon: Icon(Icons.info_outline_rounded),

                child: Text('About'),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.github),
                title: const Text('Source Code'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/chrisstayte/countdowns'),
                ),
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.xTwitter),
                title: const Text('@chrisstayte'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => launchUrl(Uri.parse('https://x.com/chrisstayte')),
              ),
              ListTile(
                leading: const Icon(Icons.email),
                title: const Text('Contact'),
                trailing: const Text(
                  'countdowns@chrisstayte.com',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  final Uri uri = Uri(
                    scheme: 'mailto',
                    path: 'countdowns@chrisstayte.com',
                    query:
                        'subject=App Feedback&body=\n\n\nApp Version ${packageInfo?.version ?? 'Unknown'}', //add subject and body here
                  );

                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ],
          ),
          SettingsContainer(
            title: 'danger',
            children: [
              ListTile(
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Delete All Events'),
                      content: const Text('This is not reversable.'),
                      actions: [
                        TextButton(
                          child: const Text("Yes"),
                          onPressed: () async {
                            var settings = ref.read(localSettingsProvider);
                            if (settings.hapticFeedback) {
                              HapticFeedback.lightImpact();
                            }
                            if (settings.soundEffects) {
                              AudioPlayer().play(
                                AssetSource('sounds/trash.mp3'),
                                ctx: AudioContext(
                                  iOS: AudioContextIOS(
                                    category: AVAudioSessionCategory.ambient,
                                  ),
                                ),
                                mode: PlayerMode.lowLatency,
                              );
                            }
                            await ref
                                .read(eventsControllerProvider)
                                .deleteAllEvents();
                            if (!context.mounted) return;
                            context.pop();
                          },
                        ),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: const Text('No'),
                        ),
                      ],
                    );
                  },
                ),
                title: const Text('Delete All Events'),
                trailing: const Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              children: [
                const Text(
                  'Leave a review',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Center(
                  child: GestureDetector(
                    onTap: () => InAppReview.instance.openStoreListing(
                      appStoreId: '1603744166',
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.5),
                            spreadRadius: 3,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) => const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Countdowns',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Global.colors.secondaryColor
                      : Global.colors.accentColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Version ${packageInfo?.version ?? 'Unknown'} Build ${packageInfo?.buildNumber ?? 'Unknown'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xffa6a5f6),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Made with ❤️ using flutter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xffa6a5f6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
