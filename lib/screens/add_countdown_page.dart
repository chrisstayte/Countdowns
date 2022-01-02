import 'package:countdown/models/countdown_event.dart';
import 'package:countdown/screens/settings_page.dart';
import 'package:countdown/utilities/countdowns_provider.dart';
import 'package:countdown/widgets/countdown_card_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/src/provider.dart';

class AddCountdownPage extends StatefulWidget {
  const AddCountdownPage({Key? key}) : super(key: key);

  @override
  _AddCountdownPageState createState() => _AddCountdownPageState();
}

class _AddCountdownPageState extends State<AddCountdownPage> {
  String _textBox = '';
  DateTime? _dateTime;
  Color? color;
  IconData? _icon;
  String? _fontFamily;

  final _rowHeight = 42.0;

  final List<Color> _colors = [
    const Color(0XFFBB84E7),
    const Color(0XFFA3C4F3),
    const Color(0XFF568D66),
    const Color(0XFFF15152),
    const Color(0XFFFF9500),
    const Color(0XFF0a9396),
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.grey,
    Colors.lightBlue,
    Colors.lightGreen,
    Colors.deepPurple,
    Colors.black,
    Colors.pink
  ];

  final List<IconData> _icons = [
    Icons.calendar_today,
    Icons.celebration,
    Icons.baby_changing_station,
    Icons.cake,
    Icons.local_dining,
    Icons.icecream,
    Icons.holiday_village,
    Icons.hiking,
    Icons.sports,
    Icons.sports_football,
    Icons.sports_baseball,
    Icons.sports_basketball,
    Icons.sports_esports,
    Icons.alarm,
    Icons.airplane_ticket,
    Icons.airplanemode_active,
    Icons.photo,
    Icons.wifi,
    Icons.warning
  ];

  final Map<String, String> _fonts = {
    'Default': 'Default',
    'Baskerville': 'LibreBaskerville',
    'Carnivalee Freakshow': 'CarnivaleeFreakshow',
    'Comic Neue': 'ComicNeue',
    'Good Times': 'GoodTimes',
    'Roboto': 'Roboto',
  };

  final _modalShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    ),
  );

  void showIconPicker() {
    showModalBottomSheet(
      context: context,
      shape: _modalShape,
      builder: (_) => SizedBox(
        height: 450,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
            horizontal: 8.0,
          ),
          child: Column(
            children: [
              const Text(
                'Select an Icon',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.fromLTRB(25, 15, 25, 0),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  crossAxisCount: 5,
                  children: List.generate(_icons.length, (index) {
                    return IconButton(
                      icon: Icon(_icons[index]),
                      onPressed: () {
                        setState(() {
                          _icon = _icons[index];
                        });
                      },
                    );
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: _modalShape,
      builder: (_) => SizedBox(
        height: 450,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
          ),
          child: Column(
            children: [
              const Text(
                'Select A Color',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: GridView.count(
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  crossAxisCount: 5,
                  children: List.generate(_colors.length, (index) {
                    return GestureDetector(
                        onTap: () {
                          setState(() {
                            color = _colors[index];
                          });
                        },
                        child: Container(
                          height: 25,
                          width: 25,
                          decoration: BoxDecoration(
                            color: _colors[index],
                            shape: BoxShape.circle,
                          ),
                        ));
                  }),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: const Color.fromARGB(255, 255, 255, 255),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                color: Colors.grey.shade100,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Done"),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                )),
            SizedBox(
              height: 180,
              child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: DateTime.now(),
                  onDateTimeChanged: (val) {
                    setState(() {
                      _dateTime = val;
                    });
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void showFontPicker() {
    showModalBottomSheet(
      context: context,
      shape: _modalShape,
      builder: (_) => SizedBox(
        height: 450,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
          ),
          child: Column(
            children: [
              const Text(
                'Select A Font',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _fonts.length,
                  itemBuilder: (context, index) {
                    List<String> values = _fonts.values.toList();
                    return ListTile(
                      title: Text(
                        _fonts.keys.toList()[index],
                        style: TextStyle(
                          fontFamily: values[index],
                        ),
                      ),
                      onTap: () => setState(
                        () {
                          _fontFamily = values[index];
                        },
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add Countdown'),
        actions: [
          TextButton(
            onPressed: () {
              if (_textBox.isNotEmpty && _dateTime != null) {
                CountdownEvent event = CountdownEvent(
                  title: _textBox,
                  eventDate: _dateTime!,
                  color: color,
                  icon: _icon,
                  fontFamily: _fontFamily,
                );
                context.read<CountdownsProvider>().addEvent(event);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CountdownCardBuilder(
              title: _textBox,
              eventDate: _dateTime,
              color: color,
              icon: _icon,
              fontFamily: _fontFamily,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: _rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _textBox.isEmpty
                      ? const Text('Enter a name')
                      : const Text(''),
                  Flexible(
                    //BUG: Cursor keeps going to the left
                    child: TextField(
                      textCapitalization: TextCapitalization.words,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      decoration: const InputDecoration(
                        hintTextDirection: TextDirection.rtl,
                        border: InputBorder.none,
                        hintText: 'Name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _textBox = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: _rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Select a date",
                  ),
                  _dateTime == null
                      ? IconButton(
                          onPressed: showDatePicker,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          icon: const Icon(Icons.chevron_right),
                        )
                      : GestureDetector(
                          onTap: showDatePicker,
                          child: Text(
                              "${_dateTime?.month.toString()}/${_dateTime?.day.toString()}/${_dateTime?.year.toString()}"),
                        )
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: _rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Select a color"),
                  IconButton(
                    onPressed: showColorPicker,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: _rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select an icon'),
                  IconButton(
                    onPressed: showIconPicker,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(
                      Icons.chevron_right,
                    ),
                  )
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: Colors.grey.shade400),
                ),
              ),
              height: _rowHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Select a font'),
                  IconButton(
                    onPressed: showFontPicker,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(
                      Icons.chevron_right,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
