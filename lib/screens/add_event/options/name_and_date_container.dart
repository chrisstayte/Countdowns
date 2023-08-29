import 'package:countdowns/screens/add_event/date_picker_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

typedef void OnDateTimeChanged(DateTime dateTime);
typedef void OnAllDayChanged(bool allDay);

class NameAndDateContainer extends StatelessWidget {
  const NameAndDateContainer({
    super.key,
    required this.controller,
    required this.eventDateTime,
    required this.onDateTimeChanged,
    required this.allDay,
    required this.onAllDayChanged,
  });

  final TextEditingController controller;
  final DateTime eventDateTime;
  final OnDateTimeChanged onDateTimeChanged;
  final bool allDay;
  final OnAllDayChanged onAllDayChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
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
              decoration: const InputDecoration(
                hintText: 'Event Name',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          GestureDetector(
            onTap: () async {
              await Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => DatePickerScreen(
                    eventDateTime: eventDateTime,
                    allDay: allDay,
                  ),
                ),
              )
                  .then((result) {
                if (result != null) {
                  onDateTimeChanged(result[0]);
                  onAllDayChanged(result[1]);
                }
              });
            },
            child: Container(
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
                        DateFormat('MM/dd/yyyy').format(eventDateTime),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        allDay
                            ? 'All Day'
                            : DateFormat("hh:mm a").format(eventDateTime),
                      ),
                    ],
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_circle_right_sharp,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
