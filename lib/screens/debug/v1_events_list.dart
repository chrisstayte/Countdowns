import 'package:countdowns/providers/countdowns_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class V1EventList extends StatelessWidget {
  const V1EventList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('V1 Events'),
      ),
      body: ListView(
        children: context
            .watch<CountdownsProvider>()
            .events
            .map(
              (countdownEvent) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  color: Colors.white,
                  child: ListTile(
                    title: Text(countdownEvent.title),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
