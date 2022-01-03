import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/src/provider.dart';

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

  late Widget fullDivider;
  late Widget partialDivider;
  final dividerThickness = 0.75;

  @override
  void initState() {
    super.initState();

    _initPackageInfo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fullDivider = Divider(
      thickness: dividerThickness,
      color: context.watch<SettingsProvider>().settings.darkMode
          ? Colors.grey.shade700
          : Colors.grey.shade300,
    );

    partialDivider = Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Divider(
        thickness: dividerThickness,
        color: context.watch<SettingsProvider>().settings.darkMode
            ? Colors.grey.shade700
            : Colors.grey.shade300,
      ),
    );
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
          title: Text('Settings'),
          elevation: 0,
        ),
        body: ListView(
          padding: EdgeInsets.only(top: 15.0),
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'COUNTDOWNS',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            fullDivider,
            const ListTile(
              title: Text("Sorting"),
              trailing: Icon(Icons.sort_by_alpha_rounded),
            ),
            partialDivider,
            ListTile(
              onTap: () => showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete All Countdowns'),
                    content: const Text('This is not reversable.'),
                    actions: [
                      TextButton(
                        child: const Text(
                          "Yes",
                        ),
                        onPressed: () {
                          context.read<CountdownsProvider>().deleteAll();
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
              title: const Text('Delete All Countdowns'),
              trailing: const Icon(Icons.delete),
            ),
            fullDivider,
            const SizedBox(
              height: 30,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                'DESIGN',
                style: TextStyle(
                  fontSize: 10,
                ),
              ),
            ),
            fullDivider,
            ListTile(
              title: Text('Dark Theme'),
              trailing: Switch(
                value: context.watch<SettingsProvider>().settings.darkMode,
                onChanged: (isDark) =>
                    context.read<SettingsProvider>().setDarkMode(isDark),
              ),
            ),
            fullDivider,
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
            fullDivider,
            ListTile(
              title: const Text('Feedback'),
              trailing: Text('countdowns@chrisstayte.com'),
            ),
            partialDivider,
            AboutListTile(
              child: Text('About'),
            ),
            partialDivider,
            ListTile(
              title: const Text("Rate Coutndowns"),
              trailing: const Icon(Icons.rate_review),
            ),
            fullDivider,
            SizedBox(
              height: 42,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('v${_packageInfo.version}')],
              ),
            )
          ],
        )
        // body: Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 0),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.stretch,
        //     mainAxisAlignment: MainAxisAlignment.start,
        //     children: [
        //       Text('General'),
        //       Divider(
        //         color: context.watch<SettingsProvider>().settings.darkMode
        //             ? Colors.white
        //             : Colors.grey,
        //       ),
        //       SizedBox(
        //         height: 42,
        //         child: Padding(
        //           padding: const EdgeInsets.symmetric(horizontal: 8.0),
        //           child: Row(
        //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //               children: [
        //                 Text('Dark Mode'),
        //                 Switch(
        //                   value:
        //                       context.watch<SettingsProvider>().settings.darkMode,
        //                   onChanged: (isDark) => context
        //                       .read<SettingsProvider>()
        //                       .setDarkMode(isDark),
        //                 ),
        //               ]),
        //         ),
        //       ),
        //       Row(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           OutlinedButton(
        //             onPressed: () => {
        //               showDialog(
        //                 context: context,
        //                 builder: (BuildContext context) {
        //                   return AlertDialog(
        //                     title: const Text('Delete All Countdowns'),
        //                     content: const Text('This is not reversable'),
        //                     actions: [
        //                       TextButton(
        //                         onPressed: () => Navigator.pop(context),
        //                         child: Text(
        //                           'No',
        //                           style: TextStyle(color: Colors.grey.shade900),
        //                         ),
        //                       ),
        //                       TextButton(
        //                         child: Text(
        //                           "Yes",
        //                           style: TextStyle(
        //                             color: Colors.grey.shade900,
        //                           ),
        //                         ),
        //                         onPressed: () {
        //                           context.read<CountdownsProvider>().deleteAll();
        //                           Navigator.of(context)
        //                             ..pop()
        //                             ..pop();
        //                         },
        //                       )
        //                     ],
        //                   );
        //                 },
        //               )
        //             },
        //             child: const Text(
        //               "Delete All Events",
        //               style: TextStyle(color: Colors.redAccent),
        //             ),
        //             style: OutlinedButton.styleFrom(
        //               side: const BorderSide(color: Colors.redAccent),
        //             ),
        //           ),
        //         ],
        //       )
        //     ],
        //   ),
        // ),
        );
  }
}
