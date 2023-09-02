import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/main.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/debug/v1_events_list.dart';
import 'package:countdowns/screens/settings/widget/settings_container.dart';
import 'package:countdowns/providers/countdowns_provider.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
  );

  late SortingMethod _sortingMethod;

  @override
  void initState() {
    super.initState();

    _initPackageInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _sortingMethod = context.watch<SettingsProvider>().settings.sortingMethod;
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            var settings = context.read<SettingsProvider>().settings;
            if (settings.hapticFeedback) {
              HapticFeedback.lightImpact();
            }
            if (settings.soundEffects) {
              AudioPlayer().play(AssetSource('sounds/tap.mp3'),
                  ctx: const AudioContext(
                    iOS: AudioContextIOS(
                      category: AVAudioSessionCategory.ambient,
                    ),
                  ),
                  mode: PlayerMode.lowLatency);
            }
            context.pop();
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          top: 15.0,
          left: 15.0,
          right: 15.0,
          bottom: 85.0,
        ),
        children: [
          if (kDebugMode)
            SettingsContainer(
              title: 'Debug',
              children: [
                ListTile(
                  title: const Text('Inject Version 1 File'),
                  trailing: IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: () {
                      context.read<CountdownsProvider>().addRandomEvent();
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Delete Version 1 File'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      // if countdownEvents file exists delete it

                      final directory =
                          await getApplicationDocumentsDirectory();
                      File v1Path =
                          File('${directory.path}/countdownevents.json');

                      if (v1Path.existsSync()) {
                        v1Path.deleteSync();
                      }

                      ScaffoldMessenger.of(context).showMaterialBanner(
                        MaterialBanner(
                          content: const Text('Deleted V1 File'),
                          actions: [
                            IconButton(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .clearMaterialBanners(),
                              icon: const Icon(Icons.close),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Show V1 Events'),
                  trailing: IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const V1EventList(),
                        ),
                      );
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Send Notification'),
                  trailing: const Icon(Icons.notification_add),
                  onTap: () async {
                    await Future.delayed(const Duration(seconds: 2), () {
                      flutterLocalNotificationsPlugin.cancelAll();
                    });
                    flutterLocalNotificationsPlugin.show(
                      0,
                      'Countdowns',
                      'This is a test notification',
                      NotificationDetails(
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
                    String timeZone = await FlutterTimezone.getLocalTimezone();
                    print(timeZone);
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
                      print(element.id);
                    }
                  },
                )
              ],
            ),
          SettingsContainer(
            title: 'events',
            children: [
              ListTile(
                leading: const Icon(Icons.sort_rounded),
                title: const Text("Sort"),
                trailing: DropdownButton(
                  alignment: Alignment.centerRight,
                  value: _sortingMethod,
                  underline: Container(),
                  items: SortingMethod.values
                      .map((sortingMethod) => DropdownMenuItem(
                            alignment: Alignment.centerRight,
                            value: sortingMethod,
                            child: Text(
                              sortingMethod.nameReadable,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    context
                        .read<SettingsProvider>()
                        .setSortingMethod(value as SortingMethod);
                    context.read<CountdownsProvider>().sortEvents(value);
                  },
                ),
              ),
            ],
          ),
          SettingsContainer(
            title: 'Display',
            children: [
              ListTile(
                leading: const Icon(Icons.color_lens_rounded),
                title: const Text('Theme'),
                trailing: DropdownButton(
                  value: context.watch<SettingsProvider>().settings.themeMode,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem<int>(
                      value: 0,
                      child: Text('System'),
                    ),
                    DropdownMenuItem<int>(
                      value: 1,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem<int>(
                      value: 2,
                      child: Text('Dark'),
                    ),
                  ],
                  onChanged: (int? value) {
                    context.read<SettingsProvider>().setThemeMode(value!);
                  },
                ),
              ),
              if (Platform.isIOS)
                ListTile(
                  leading: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0.2237 * 28),
                    ),
                    child: Image.asset(
                      'assets/images/icons/icon-${context.watch<SettingsProvider>().settings.iconName}.png',
                      height: 28,
                    ),
                  ),
                  title: const Text('App Icon'),
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () => context.push('/settings/appIcon'),
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
                  value:
                      context.watch<SettingsProvider>().settings.soundEffects,
                  onChanged: (value) {
                    context.read<SettingsProvider>().setSoundEffectsMode(value);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.vibration_rounded),
                title: const Text('Haptic Feedback'),
                trailing: Switch.adaptive(
                  value:
                      context.watch<SettingsProvider>().settings.hapticFeedback,
                  onChanged: (value) {
                    context
                        .read<SettingsProvider>()
                        .setHapticFeedbackMode(value);
                  },
                ),
              ),
            ],
          ),
          SettingsContainer(
            title: 'Notifications',
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('When Event Ends'),
                trailing: Switch.adaptive(
                  value: context.watch<SettingsProvider>().settings.notify,
                  onChanged: (value) async {
                    // If the user is requesting to turn them off, simply do so.
                    if (!value) {
                      // TODO: delete all pending notifications
                      context.read<SettingsProvider>().setNotify(value);
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
                        )
                      ],
                    );

                    if (Platform.isIOS) {
                      final bool? permissionGranted =
                          await flutterLocalNotificationsPlugin
                              .resolvePlatformSpecificImplementation<
                                  IOSFlutterLocalNotificationsPlugin>()
                              ?.requestPermissions(
                                alert: true,
                                badge: true,
                                sound: true,
                              );

                      if (permissionGranted != null) {
                        if (permissionGranted) {
                          if (!mounted) return;
                          context.read<SettingsProvider>().setNotify(true);
                          context
                              .read<EventProvider>()
                              .events
                              .forEach((event) => event.scheduleNotification());
                        } else {
                          if (!mounted) return;
                          await showDialog(
                            context: context,
                            builder: (context) => goToSettingsAlertDialog,
                          );
                          return;
                        }
                      }
                    }

                    if (Platform.isAndroid) {
                      bool? permissionGranted =
                          await flutterLocalNotificationsPlugin
                              .resolvePlatformSpecificImplementation<
                                  AndroidFlutterLocalNotificationsPlugin>()
                              ?.requestPermission();

                      if (!mounted) return;

                      if (permissionGranted != null) {
                        if (permissionGranted) {
                          if (!mounted) return;
                          context.read<SettingsProvider>().setNotify(true);
                          context
                              .read<EventProvider>()
                              .events
                              .forEach((event) => event.scheduleNotification());
                        } else {
                          if (!mounted) return;
                          await showDialog(
                            context: context,
                            builder: (context) => goToSettingsAlertDialog,
                          );
                          return;
                        }
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          SettingsContainer(title: 'support', children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => launchUrl(
                  Uri.parse('https://chrisstayte.app/countdowns/privacy/')),
            ),
            ListTile(
              leading: const Icon(Icons.article_rounded),
              title: const Text('Terms of Use'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => launchUrl(
                  Uri.parse('https://chrisstayte.app/countdowns/terms/')),
            ),
            const AboutListTile(
              icon: Icon(Icons.info_outline_rounded),
              applicationName: 'Countdowns',
              applicationIcon: Icon(Icons.info_outline_rounded),
              applicationLegalese: 'What am I made of?',
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
              leading: const Icon(Icons.email),
              title: const Text('Contact'),
              trailing: const Text(
                'countdowns@chrisstayte.com',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
              onTap: () async {
                final Uri uri = Uri(
                  scheme: 'mailto',
                  path: 'countdowns@chrisstayte.com',
                  query:
                      'subject=App Feedback&body=\n\n\nApp Version ${_packageInfo.version}', //add subject and body here
                );

                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
            )
          ]),
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
                          child: const Text(
                            "Yes",
                          ),
                          onPressed: () {
                            var settings =
                                context.read<SettingsProvider>().settings;
                            if (settings.hapticFeedback) {
                              HapticFeedback.lightImpact();
                            }
                            if (settings.soundEffects) {
                              AudioPlayer().play(
                                  AssetSource('sounds/trash.mp3'),
                                  ctx: const AudioContext(
                                    iOS: AudioContextIOS(
                                      category: AVAudioSessionCategory.ambient,
                                    ),
                                  ),
                                  mode: PlayerMode.lowLatency);
                            }
                            context.read<EventProvider>().deleteAllEvents();
                            Navigator.pop(context);
                          },
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'No',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                title: const Text('Delete All Events'),
                trailing: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              children: [
                const Text(
                  'Leave a review',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
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
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ]),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) => const Icon(Icons.star_rounded,
                              color: Colors.amber),
                        ),
                      ),
                    ),
                  ),
                )
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
                'Version ${_packageInfo.version} Build ${_packageInfo.buildNumber}',
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
