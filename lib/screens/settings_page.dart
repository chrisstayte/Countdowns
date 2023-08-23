import 'package:countdowns/enums/sorting_method.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/setttings/credits_page.dart';
import 'package:countdowns/screens/setttings/widget/settings_container.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/src/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
          centerTitle: false,
          elevation: 0,
        ),
        backgroundColor: Color(0XFFDEE2FF),
        body: ListView(
          padding: const EdgeInsets.only(
            top: 15.0,
            left: 15.0,
            right: 15.0,
          ),
          children: [
            SettingsContainer(title: 'events', children: [
              ListTile(
                title: const Text("Sort"),
                trailing: DropdownButton(
                  // dropdownColor:
                  // context.watch<SettingsProvider>().settings.darkMode
                  //     ? Global.colors.darkIconColor
                  //     : Global.colors.lightIconColor,
                  value: _sortingMethod,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem<SortingMethod>(
                      child: FaIcon(FontAwesomeIcons.arrowDownAZ),
                      value: SortingMethod.alphaAscending,
                    ),
                    DropdownMenuItem<SortingMethod>(
                      child: FaIcon(FontAwesomeIcons.arrowDownZA),
                      value: SortingMethod.alphaDescending,
                    ),
                    DropdownMenuItem<SortingMethod>(
                      child: FaIcon(FontAwesomeIcons.arrowDown19),
                      value: SortingMethod.dateAscending,
                    ),
                    DropdownMenuItem<SortingMethod>(
                      child: FaIcon(FontAwesomeIcons.arrowDown91),
                      value: SortingMethod.dateDescending,
                    )
                  ],
                  onChanged: (value) {
                    context
                        .read<SettingsProvider>()
                        .setSortingMethod(value as SortingMethod);
                    context.read<CountdownsProvider>().sortEvents(value);
                  },
                ),
              ),
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
                trailing: const Icon(Icons.delete),
              ),
            ]),

            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'DISPLAY',
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            ),

            Container(
              child: Column(children: [
                ListTile(
                  title: const Text('Dark Theme'),
                  // trailing: Switch(
                  //   value: context.watch<SettingsProvider>().settings.darkMode,
                  //   onChanged: (isDark) =>
                  //       context.read<SettingsProvider>().setDarkMode(isDark),
                  // ),
                ),
                ListTile(
                    // title: const Text('Dark Theme'),
                    // trailing: Switch(
                    //   value: context.watch<SettingsProvider>().settings.darkMode,
                    //   onChanged: (isDark) =>
                    //       context.read<SettingsProvider>().setDarkMode(isDark),
                    // ),
                    ),
              ]),
            ),
            const SizedBox(
              height: 30,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'INFO',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),

            ListTile(
              title: const Text('Feedback'),
              trailing: const Text('countdowns@chrisstayte.com'),
              onTap: () async {
                final Uri params = Uri(
                  scheme: 'mailto',
                  path: 'countdowns@chrisstayte.com',
                  query:
                      'subject=App Feedback&body=\n\n\nApp Version ${_packageInfo.version}', //add subject and body here
                );

                final String url = params.toString();
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
            ),

            const AboutListTile(
              child: Text('About'),
            ),

            // ListTile(
            //   title: const Text("Rate Countdowns"),
            //   trailing: const Icon(Icons.rate_review),
            //   onTap: () {
            //     StoreRedirect.redirect();
            //   },
            // ),

            // ListTile(
            //   title: const Text('Credits'),
            //   trailing: const Icon(Icons.chevron_right_rounded),
            //   onTap: () => Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //       builder: (context) {
            //         return CreditsPage();
            //       },
            //     ),
            //   ),
            // ),
            SizedBox(
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(label: Text('v${_packageInfo.version}')),
                  const Chip(
                    label: SizedBox(
                        height: 28, child: Text('Made with ❤️ using flutter')),
                  )
                ],
              ),
            ),
          ],
        ));
  }
}
