import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/screens/settings_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/widgets/countdown_card_builder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:provider/src/provider.dart';

class AddCountdownPage extends StatefulWidget {
  const AddCountdownPage({Key? key}) : super(key: key);

  @override
  _AddCountdownPageState createState() => _AddCountdownPageState();
}

class _AddCountdownPageState extends State<AddCountdownPage> {
  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    _focusNode.dispose();

    super.dispose();
  }

  String _textBox = '';
  DateTime? _dateTime;
  Color? _color;
  IconData? _icon;
  String? _fontFamily;
  String? _selectedFont;
  Color? _contentColor;

  late FocusNode _focusNode;

  final _rowHeight = 42.0;

  final List<Color> _colors = [
    const Color(0XFFBB84E7),
    const Color(0XFFA3C4F3),
    const Color(0XFF568D66),
    const Color(0XFFF15152),
    const Color(0XFFFF9500),
    const Color(0XFF0a9396),
    const Color(0XFFF7E7CE),
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
    Colors.pink,
    Colors.white,
    Colors.brown,
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
    Icons.warning,
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

  void _showIconPicker() {
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

  void _showColorPickerForBackground() {
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
                            _color = _colors[index];
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

//TODO: add dark theme to  this
  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
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

  void _showFontPicker() {
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
                    List<String> keys = _fonts.keys.toList();
                    List<String> values = _fonts.values.toList();
                    return ListTile(
                      title: Text(
                        keys[index],
                        style: TextStyle(
                          fontFamily: values[index],
                        ),
                      ),
                      onTap: () => setState(
                        () {
                          _fontFamily = values[index];
                          _selectedFont = keys[index];
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

  void _showColorPickerForFont() {
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
                            _contentColor = _colors[index];
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
                  color: _color,
                  icon: _icon,
                  fontFamily: _fontFamily,
                  contentColor: _contentColor,
                );
                context.read<CountdownsProvider>().addEvent(event);
                Navigator.pop(context);
              }
            },
            child: Text('Add'),
          )
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Hero(
                tag: 'emptycard',
                child: CountdownCardBuilder(
                  title: _textBox,
                  eventDate: _dateTime,
                  color: _color,
                  icon: _icon,
                  fontFamily: _fontFamily,
                  contentColor: _contentColor,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  title: Row(
                    children: [
                      _textBox.isEmpty ? Text('Name') : Text(''),
                      Flexible(
                        //BUG: Cursor keeps going to the left
                        child: TextField(
                          focusNode: _focusNode,
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
                            setState(
                              () {
                                _textBox = value;
                              },
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
                ListTile(
                  onTap: () => _showDatePicker(),
                  title: Text('Date'),
                  trailing: _dateTime == null
                      ? Icon(Icons.chevron_right_rounded)
                      : Text(
                          '${_dateTime?.month.toString()}/${_dateTime?.day.toString()}/${_dateTime?.year.toString()}'),
                ),
                ListTile(
                  onTap: () => _showColorPickerForBackground(),
                  title: Text('Color'),
                  trailing: Icon(
                    Icons.circle,
                    color: _color,
                  ),
                ),
                ListTile(
                  onTap: () => _showIconPicker(),
                  title: Text('Icon'),
                  trailing: _icon == null
                      ? Icon(Icons.chevron_right_rounded)
                      : Icon(_icon),
                ),
                ListTile(
                  onTap: () => _showFontPicker(),
                  title: Text('Font'),
                  trailing: _fontFamily == null
                      ? Text('Regular')
                      : Text(_selectedFont!),
                ),
                ListTile(
                  onTap: () => _showColorPickerForFont(),
                  title: Text('Content Color'),
                  trailing: _contentColor == null
                      ? Icon(Icons.circle)
                      : Icon(
                          Icons.circle,
                          color: _contentColor,
                        ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
