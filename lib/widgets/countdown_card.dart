import 'package:countdown/models/countdown_event.dart';
import 'package:countdown/utilities/functions.dart';
import 'package:flutter/material.dart';

/// This countdown card is used to show on the homescreen.
/// It takes a [CountdownEvent] object and sets the information on the card accordingly
class CountdownCard extends StatefulWidget {
  const CountdownCard({Key? key, required this.event}) : super(key: key);
  final CountdownEvent event;

  @override
  _CountdownCardState createState() => _CountdownCardState();
}

class _CountdownCardState extends State<CountdownCard> {
  @override
  void initState() {
    super.initState();
    getStatus();
  }

  List<Widget> getStatus() {
    List<Widget> widgets = [];

    DateTime currentDate = DateTime.now();

    int numberOfDays = numberOfDaysBetween(currentDate, widget.event.eventDate);

    if (numberOfDays < 0) {
      widgets = [
        const Icon(
          Icons.done,
          color: Colors.white,
        ),
        Text(
          '${widget.event.eventDate.month}.${widget.event.eventDate.day}.${widget.event.eventDate.year}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        )
      ];
    } else if (numberOfDays > 0) {
      widgets = [
        Text(
          numberOfDays.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          numberOfDays == 1 ? 'DAY' : 'DAYS',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ];
    } else {
      widgets = const [
        Icon(
          Icons.done,
          color: Colors.white,
        ),
        Text(
          'TODAY',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: Colors.white,
          ),
        )
      ];
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Card(
        color: widget.event.color ?? Colors.blue,
        elevation: 1.0,
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  widget.event.icon ?? Icons.calendar_today,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Text(
                  widget.event.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
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
        ),
      ),
    );
  }
}
