import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventSquareConstructor extends StatelessWidget {
  const EventSquareConstructor({
    super.key,
    required this.title,
    this.icon,
    this.fontFamily,
    this.dateTime,
  });

  final String title;
  final IconData? icon;
  final String? fontFamily;
  final DateTime? dateTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 169,
      height: 169,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          25,
        ),
        color: Global.colors.primaryColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AutoSizeText(
                  title,
                  minFontSize: 14,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                )
            ],
          ),
          if (dateTime != null)
            Text(
              DateFormat('MM/dd/yy').format(dateTime!),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
