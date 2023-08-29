import 'package:countdowns/models/event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventScreen2 extends StatefulWidget {
  const EventScreen2({super.key, required this.eventKey});

  final String eventKey;

  @override
  State<EventScreen2> createState() => _EventScreen2State();
}

class _EventScreen2State extends State<EventScreen2> {
  final Event? _countdownEvent = null;

  @override
  Widget build(BuildContext context) {
    if (_countdownEvent == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text('Event Not Found'),
        ),
      );
    }

    return Container();
  }
}
