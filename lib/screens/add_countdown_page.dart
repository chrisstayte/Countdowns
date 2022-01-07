import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/screens/settings_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:countdowns/widgets/color_picker_material_modal.dart';
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
    Icons.airline_seat_flat,
    Icons.photo,
    Icons.wifi,
    Icons.warning,
    Icons.baby_changing_station,
    Icons.apartment,
    Icons.card_giftcard,
    Icons.computer,
    Icons.book,
    Icons.bookmark,
    Icons.piano,
    Icons.donut_large,
    Icons.camera,
    Icons.animation,
    Icons.sports_cricket,
    Icons.agriculture,
    Icons.horizontal_distribute_sharp,
    Icons.music_note,
    Icons.music_video,
    Icons.snooze,
    Icons.school,
    Icons.work,
    Icons.business,
    Icons.group,
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

  void _showDatePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add Countdown'),
        actions: [
          TextButton(
            style: ButtonStyle(
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              foregroundColor: MaterialStateProperty.all(
                context.watch<SettingsProvider>().settings.darkMode
                    ? Colors.white
                    : Color(0XFF536372),
              ),
            ),
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
                // TODO: add a visible message if the user does not add a name or date
                context.read<CountdownsProvider>()
                  ..addEvent(event)
                  ..sortEvents(
                    context.read<SettingsProvider>().settings.sortingMethod,
                  );
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
                      Flexible(
                        child: TextField(
                          focusNode: _focusNode,
                          textCapitalization: TextCapitalization.words,
                          textDirection: TextDirection.ltr,
                          style:
                              // subtitle1 was used because this is the default text theme of a 'listTile'
                              Theme.of(context).textTheme.subtitle1?.copyWith(
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          decoration: InputDecoration(
                            hintStyle: Theme.of(context).textTheme.subtitle1,
                            hintTextDirection: TextDirection.ltr,
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
                  onTap: () => showModalBottomSheet(
                    isScrollControlled: true,
                    shape: _modalShape,
                    context: context,
                    builder: (context) => ColorPickerMaterialModal(
                      color: _contentColor,
                      colorCallback: (color) => setState(
                        () {
                          _color = color;
                        },
                      ),
                    ),
                  ),
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
                  onTap: () => showModalBottomSheet(
                    isScrollControlled: true,
                    shape: _modalShape,
                    context: context,
                    builder: (context) => ColorPickerMaterialModal(
                      color: _contentColor,
                      colorCallback: (color) => setState(
                        () {
                          _contentColor = color;
                        },
                      ),
                    ),
                  ),
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
