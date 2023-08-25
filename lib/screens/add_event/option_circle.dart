import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OptionCircle extends StatelessWidget {
  const OptionCircle({super.key, required this.selected, required this.icon});

  final bool selected;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(
          selected ? 3 : 2,
        ),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? Global.colors.primaryColor
              : Theme.of(context).dividerColor,
        ),
        child: Container(
          padding: EdgeInsets.all(
            selected ? 11 : 12,
          ),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? Theme.of(context).appBarTheme.backgroundColor
                : Theme.of(context).scaffoldBackgroundColor,
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            return Icon(
              icon,
              color: Global.colors.primaryColor,
              size: constraints.biggest.shortestSide,
            );
          }),
        ),
      ),
    );
  }
}
