import 'package:countdown/models/countdown_event.dart';
import 'package:countdown/utilities/my_countdowns.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class CountdownPage extends StatefulWidget {
  final CountdownEvent countdownEvent;

  const CountdownPage({Key? key, required this.countdownEvent})
      : super(key: key);

  @override
  _CountdownPageState createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  final TextStyle numberStyle = const TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  final TextStyle labelStyle = const TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w300,
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Icon(
          widget.countdownEvent.icon ?? Icons.calendar_today,
          color: Colors.white,
          size: 32.0,
        ),
        elevation: 0,
        backgroundColor: widget.countdownEvent.color ?? Colors.blue,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Delete This Countdown?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'No',
                          style: TextStyle(color: Colors.grey.shade900),
                        ),
                      ),
                      TextButton(
                        child: Text(
                          "Yes",
                          style: TextStyle(
                            color: Colors.grey.shade900,
                          ),
                        ),
                        onPressed: () {
                          context
                              .read<MyCountdowns>()
                              .deleteEvent(widget.countdownEvent);
                          Navigator.of(context)
                            ..pop()
                            ..pop();
                        },
                      )
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.delete),
          )
        ],
      ),
      backgroundColor: widget.countdownEvent.color ?? Colors.blue,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 44,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.countdownEvent.title,
                      overflow: TextOverflow.visible,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 35,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "35",
                      textAlign: TextAlign.center,
                      style: numberStyle,
                    ),
                    Text("Hours", style: labelStyle)
                  ],
                ),
                Column(
                  children: [
                    Text("35", style: numberStyle),
                    Text(
                      "Minutes",
                      style: labelStyle,
                    )
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "35",
                      style: numberStyle,
                    ),
                    Text(
                      "Seconds",
                      style: labelStyle,
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 15,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      "35",
                      style: numberStyle,
                    ),
                    Text("Days", style: labelStyle)
                  ],
                ),
                Column(
                  children: [
                    Text("35", style: numberStyle),
                    Text(
                      "Months",
                      style: labelStyle,
                    )
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "35",
                      style: numberStyle,
                    ),
                    Text(
                      "Years",
                      style: labelStyle,
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
