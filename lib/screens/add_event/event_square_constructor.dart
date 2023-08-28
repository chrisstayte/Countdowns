import 'package:auto_size_text/auto_size_text.dart';
import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EventSquareConstructor extends StatelessWidget {
  const EventSquareConstructor({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

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
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
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
          )
        ],
      ),
    );
  }
}
