import 'package:flutter/material.dart';

/// This is the countdown card that is used to show a preview on the 'add countdown page'
class CountdownCardBuilder extends StatelessWidget {
  final String? title;
  final DateTime? eventDate;
  final IconData? icon;
  final Color? color;

  const CountdownCardBuilder(
      {Key? key, this.title, this.eventDate, this.icon, this.color})
      : super(key: key);

  List<Widget> getStatus() {
    List<Widget> widgets = [];

    DateTime currentDate = DateTime.now();

    if (eventDate == null) return widgets;

    int numberOfDays = eventDate!.difference(currentDate).inDays;

    if (numberOfDays < 0) {
      widgets = [
        Icon(
          Icons.done,
          color: color != null ? Colors.white : Colors.black,
        ),
        Text(
          '${eventDate?.month}.${eventDate?.day}.${eventDate?.year}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: color != null ? Colors.white : Colors.black,
          ),
        )
      ];
    } else if (numberOfDays > 0) {
      widgets = [
        Text(
          numberOfDays.toString(),
          style: TextStyle(
            fontSize: 16,
            color: color != null ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          numberOfDays == 1 ? 'DAY' : 'DAYS',
          style: TextStyle(
            color: color != null ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ];
    } else {
      widgets = [
        Icon(
          Icons.done,
          color: color != null ? Colors.white : Colors.black,
        ),
        Text(
          'TODAY',
          style: TextStyle(
            fontSize: 12,
            color: color != null ? Colors.white : Colors.black,
            fontWeight: FontWeight.w300,
          ),
        )
      ];
    }

    return widgets;
  }

  Widget getRow() => Row(
        children: [
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                icon ?? Icons.calendar_today,
                color: color != null ? Colors.white : Colors.black,
                size: 24,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: Text(
                title ?? '',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color != null ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
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
    return color != null
        ? SizedBox(
            height: 74,
            child: Card(color: color, child: getRow()),
          )
        : Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(4.0),
              ),
            ),
            height: 74,
            child: getRow(),
          );
  }
}
