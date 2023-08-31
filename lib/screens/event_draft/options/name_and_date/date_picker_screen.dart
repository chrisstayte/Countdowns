import 'package:countdowns/global/global.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerScreen extends StatefulWidget {
  const DatePickerScreen({
    super.key,
    this.eventDateTime,
    required this.allDay,
  });

  final DateTime? eventDateTime;
  final bool allDay;

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  late DateTime _dateTime;
  late bool _allDay;

  @override
  void initState() {
    _dateTime = widget.eventDateTime ?? DateTime.now();
    _allDay = widget.allDay;
    super.initState();
  }

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
                onDateChanged: (dateTime) => _dateTime = DateTime(
                  dateTime.year,
                  dateTime.month,
                  dateTime.day,
                  _dateTime.hour,
                  _dateTime.minute,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                borderRadius: Global.styles.containerCornerRadius,
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                children: [
                  ListTile(
                    title: _allDay ? const Text('All Day') : null,
                    leading: !_allDay
                        ? TextButton(
                            onPressed: () async {
                              await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                  hour: _dateTime.hour,
                                  minute: _dateTime.minute,
                                ),
                              ).then((value) {
                                if (value != null) {
                                  setState(() {
                                    _dateTime = DateTime(
                                        _dateTime.year,
                                        _dateTime.month,
                                        _dateTime.day,
                                        value.hour,
                                        value.minute);
                                  });
                                }
                              });
                            },
                            child: Text(
                              DateFormat("hh:mm a").format(_dateTime),
                            ),
                          )
                        : null,
                    trailing: Switch.adaptive(
                      value: _allDay,
                      onChanged: (value) => setState(() => _allDay = value),
                    ),
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
