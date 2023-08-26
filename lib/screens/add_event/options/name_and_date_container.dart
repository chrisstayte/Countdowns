import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

typedef void OnDateTimeChanged(DateTime dateTime);

class NameAndDateContainer extends StatelessWidget {
  const NameAndDateContainer({
    super.key,
    required this.controller,
    required this.dateTime,
    required this.onDateTimeChanged,
  });

  final TextEditingController controller;
  final DateTime dateTime;
  final OnDateTimeChanged onDateTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 5,
              horizontal: 15,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                15,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Event Name',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 15,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                15,
              ),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month_rounded,
                ),
                SizedBox(
                  width: 15,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${dateTime.day}/${dateTime.month}/${dateTime.year}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('All Day'),
                  ],
                ),
                Spacer(),
                Icon(
                  Icons.arrow_circle_right_sharp,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
