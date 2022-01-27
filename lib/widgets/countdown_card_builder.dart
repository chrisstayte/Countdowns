import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

/// This is the countdown card that is used to show a preview on the 'add countdown page'
class CountdownCardBuilder extends StatelessWidget {
  final String? title;
  final DateTime? eventDate;
  final IconData? icon;
  final Color? color;
  final String? fontFamily;
  final Color? contentColor;

  CountdownCardBuilder({
    Key? key,
    this.title,
    this.eventDate,
    this.icon,
    this.color,
    this.fontFamily,
    this.contentColor,
  }) : super(key: key);

  late Color? defaultContentColor = contentColor != null
      ? contentColor!
      : color != null
          ? color!.computeLuminance() > 0.5
              ? Global.colors.darkIconColor
              : Global.colors.lightIconColor
          : Global.colors.defaultContentColor;

  List<Widget> getStatus() {
    List<Widget> widgets = [];

    DateTime currentDate = DateTime.now();

    if (eventDate == null) return widgets;

    int numberOfDays = eventDate!.difference(currentDate).inDays;
    if (eventDate!.difference(currentDate).inSeconds > 0) {
      numberOfDays++;
    }

    if (numberOfDays < 0) {
      widgets = [
        Icon(
          Icons.done,
          color: defaultContentColor,
        ),
        Text(
          '${eventDate?.month}.${eventDate?.day}.${eventDate?.year}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: defaultContentColor,
            fontFamily: fontFamily,
          ),
        )
      ];
    } else if (numberOfDays > 0) {
      widgets = [
        Text(
          numberOfDays.toString(),
          style: TextStyle(
            fontSize: 16,
            color: defaultContentColor,
            fontWeight: FontWeight.bold,
            fontFamily: fontFamily,
          ),
        ),
        Text(
          numberOfDays == 1 ? 'DAY' : 'DAYS',
          style: TextStyle(
            color: defaultContentColor,
            fontSize: 12,
            fontWeight: FontWeight.w300,
            fontFamily: fontFamily,
          ),
        ),
      ];
    } else {
      widgets = [
        Icon(
          Icons.done,
          color: defaultContentColor,
        ),
        Text(
          'TODAY',
          style: TextStyle(
            fontSize: 12,
            color: defaultContentColor,
            fontWeight: FontWeight.w300,
            fontFamily: fontFamily,
          ),
        )
      ];
    }

    return widgets;
  }

  Widget getRow() => Row(
        children: [
          SizedBox(
            width: 50,
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                icon ?? Icons.calendar_today,
                color: defaultContentColor,
                size: 26,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: AutoSizeText(
                title ?? '',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  // color: color != null ? Colors.white : null,
                  color: defaultContentColor,
                  fontFamily: fontFamily,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: getStatus(),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      decoration: BoxDecoration(
        color: color ?? Global.colors.defaultBackgroundColor,
        borderRadius: const BorderRadius.all(
          Radius.circular(20.0),
        ),
      ),
      child: getRow(),
    );
  }
}
