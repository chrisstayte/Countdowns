import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';

class EventSquareConstructor extends StatelessWidget {
  const EventSquareConstructor({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 169,
      height: 169,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          25,
        ),
        color: Global.colors.primaryColor,
      ),
    );
  }
}
