import 'package:countdown/utilities/my_countdowns.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              OutlinedButton(
                onPressed: () => context.read<MyCountdowns>().deleteAll(),
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
