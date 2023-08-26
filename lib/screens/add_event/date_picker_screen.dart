import 'package:countdowns/global/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerScreen extends StatefulWidget {
  const DatePickerScreen({super.key});

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  DateTime _dateTime = DateTime.now();
  bool _allDay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pop(context, [
                _dateTime,
                _allDay,
              ]);
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: Global.styles.containerCornerRadius,
                color: Theme.of(context).cardColor,
              ),
              child: CalendarDatePicker(
                initialDate: _dateTime,
                firstDate: DateTime(DateTime.now().year - 100),
                lastDate: DateTime(DateTime.now().year + 100),
                onDateChanged: (dateTime) => {
                  setState(() {
                    _dateTime = dateTime;
                  })
                },
              ),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: Global.styles.containerCornerRadius,
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: _allDay ? Text('All Day') : null,
                    leading: !_allDay
                        ? TextButton(
                            onPressed: () {
                              showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                            },
                            child: Text(
                              DateFormat("hh:mm a").format(_dateTime),
                            ),
                          )
                        : null,
                    trailing: Switch.adaptive(
                        value: _allDay,
                        onChanged: (value) => setState(() => _allDay = value)),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
