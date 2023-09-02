import 'dart:io';

import 'package:countdowns/providers/settings_provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'package:provider/provider.dart';

class IOSCustomIconScreen extends StatelessWidget {
  const IOSCustomIconScreen({super.key});

  final List<String> iconNameList = const ['light', 'dark', 'original'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: iconNameList.map((name) => IconListTile(name: name)).toList(),
      ),
    );
  }
}

class IconListTile extends StatelessWidget {
  const IconListTile({
    super.key,
    required this.name,
  });

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child: ListTile(
        onTap: () async {
          try {
            if (await FlutterDynamicIcon.supportsAlternateIcons) {
              await FlutterDynamicIcon.setAlternateIconName('icon-$name');
              context.read<SettingsProvider>().setIconName(name);
              return;
            }
          } catch (e) {
            print(e);
          }
        },
        trailing: context.watch<SettingsProvider>().settings.iconName == name &&
                Platform.isIOS
            ? const Icon(
                Icons.check_circle,
              )
            : null,
        title: Text(
          name.capitalize,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: Container(
          clipBehavior: Clip.hardEdge,
          decoration:
              BoxDecoration(borderRadius: BorderRadius.circular(0.2237 * 64)),
          child: Image.asset(
            'assets/images/icons/icon-${name}.png',
            height: 64,
          ),
        ),
      ),
    );
  }
}
