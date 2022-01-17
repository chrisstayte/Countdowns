import 'package:countdowns/utilities/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class DatePickerCupertinoModal extends StatefulWidget {
  DatePickerCupertinoModal(
      {Key? key, this.dateTime, required this.dateTimeCallback})
      : super(key: key);

  DateTime? dateTime;
  DateTimeCallback dateTimeCallback;

  @override
  _DatePickerCupertinoModalState createState() =>
      _DatePickerCupertinoModalState();
}

typedef void DateTimeCallback(DateTime dateTime);

class _DatePickerCupertinoModalState extends State<DatePickerCupertinoModal> {
  DateTime? _dateTime;

  @override
  void initState() {
    _dateTime = widget.dateTime;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.watch<SettingsProvider>().settings.darkMode
          ? const Color(0XFF303030)
          : Colors.white,
      height: 250,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
              color: context.watch<SettingsProvider>().settings.darkMode
                  ? Color(0XFF424242)
                  : Colors.white,
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text("Done"),
                    onPressed: () => Navigator.pop(context),
                    style: ButtonStyle(
                      overlayColor:
                          MaterialStateProperty.all(Colors.transparent),
                      foregroundColor: MaterialStateProperty.all(
                        context.watch<SettingsProvider>().settings.darkMode
                            ? Colors.white
                            : Color(0XFF536372),
                      ),
                    ),
                  ),
                ],
              )),
          SizedBox(
            height: 180,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: _dateTime ?? DateTime.now(),
              onDateTimeChanged: (val) {
                setState(
                  () {
                    _dateTime = val;
                  },
                );
                widget.dateTimeCallback(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}
