import 'package:countdown/utilities/my_countdowns.dart';
import 'package:countdown/utilities/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Switch(
                value: context.watch<Settings>().darkMode,
                onChanged: (isDark) =>
                    context.read<Settings>().setDarkMode(isDark),
              ),
              TextButton(
                onPressed: () => context.read<Settings>().changeFont(),
                child: Text('Change Font'),
              ),
              OutlinedButton(
                onPressed: () => {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete All Countdowns'),
                        content: const Text('This is not reversable'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'No',
                              style: TextStyle(color: Colors.grey.shade900),
                            ),
                          ),
                          TextButton(
                            child: Text(
                              "Yes",
                              style: TextStyle(
                                color: Colors.grey.shade900,
                              ),
                            ),
                            onPressed: () {
                              context.read<MyCountdowns>().deleteAll();
                              Navigator.of(context)
                                ..pop()
                                ..pop();
                            },
                          )
                        ],
                      );
                    },
                  )
                },
                child: const Text(
                  "Delete All Events",
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
