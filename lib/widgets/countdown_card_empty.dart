import 'package:countdowns/global/global.dart';
import 'package:flutter/material.dart';

class CountdownCardEmpty extends StatelessWidget {
  const CountdownCardEmpty({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Global.colors.defaultBackgroundColor,
        borderRadius: BorderRadius.all(
          Radius.circular(45.0),
        ),
      ),
      width: 175,
      height: 175,
      child: Center(
        child: Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Icon(
            Icons.add_rounded,
            size: 55,
            color: Global.colors.defaultBackgroundColor,
          ),
        ),
      ),
    );
  }
}
