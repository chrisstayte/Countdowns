import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/setttings/widget/settings_container.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/src/provider.dart';
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
        ),
        body: ListView(
          padding: const EdgeInsets.only(
            top: 15.0,
            left: 15.0,
            right: 15.0,
            bottom: 85.0,
          ),
          children: [
            SettingsContainer(title: 'events', children: [
              ListTile(
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
            ]),
            SettingsContainer(title: 'Display', children: [
              ListTile(
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
            ]),
            SettingsContainer(
              title: 'sounds and haptics',
              children: [
                ListTile(
                  title: const Text('Sounds Effects'),
                  trailing: Switch.adaptive(
                    value:
                        context.watch<SettingsProvider>().settings.soundEffects,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .setSoundEffectsMode(value);
                    },
                  ),
                ),
                ListTile(
                  title: const Text('Haptic Feedback'),
                  trailing: Switch.adaptive(
                    value: context
                        .watch<SettingsProvider>()
                        .settings
                        .hapticFeedback,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .setHapticFeedbackMode(value);
                    },
                  ),
                ),
              ],
            ),
            SettingsContainer(title: 'support', children: [
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => launchUrl(
                    Uri.parse('https://chrisstayte.app/countdowns/privacy/')),
              ),
              ListTile(
                title: const Text('Terms of Use'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => launchUrl(
                    Uri.parse('https://chrisstayte.app/countdowns/terms/')),
              ),
              AboutListTile(
                applicationName: 'Countdowns',
                applicationVersion: _packageInfo.version,
                applicationIcon: const Icon(Icons.info_outline_rounded),
                applicationLegalese: 'What am I made of?',
                child: const Text('About'),
              ),
              ListTile(
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
        ));
  }
}
