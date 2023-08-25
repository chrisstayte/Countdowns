import 'package:countdowns/global/global.dart';
import 'package:flutter/material.dart';

class CountdownCardEmpty extends StatelessWidget {
  const CountdownCardEmpty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Global.colors.primaryColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(20.0),
        ),
      ),
      height: 85,
      child: Center(
        child: Container(
          width: 45,
          height: 45,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            // color: context.watch<SettingsProvider>().settings.darkMode
            //     ? Global.colors.darkIconColor
            //     : Global.colors.lightIconColor,
          ),
          child: Icon(
            Icons.add_rounded,
            size: 25,
            color: Global.colors.primaryColor,
          ),
        ),
      ),
    );
  }
}
