import 'package:countdowns/models/event.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CountdownSquare extends StatelessWidget {
  const CountdownSquare({super.key, required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push(
          '/event/${event.key}',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: event.backgroundColor ?? Color(0xff7877E6),
        ),
        width: 169,
        height: 169,
        child: Center(
          child: Text(
            event.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
