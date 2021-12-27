import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

/// This countdown card is used to show on the homescreen when there are not countdown events at all
class CountdownCardEmpty extends StatelessWidget {
  const CountdownCardEmpty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(4.0),
        padding: EdgeInsets.zero,
        dashPattern: const [7],
        color: Colors.black,
        strokeWidth: 1.5,
        child: Row(
          children: const [
            SizedBox(
              width: 44,
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.black,
                  size: 24,
                ),
              ),
            ),
            Text(
              'Add a countdown',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
