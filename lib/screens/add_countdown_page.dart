import 'package:countdowns/models/countdown_event.dart';
import 'package:countdowns/screens/settings_page.dart';
import 'package:countdowns/utilities/countdowns_provider.dart';
import 'package:countdowns/utilities/settings_provider.dart';
import 'package:countdowns/widgets/color_picker_material_modal.dart';
import 'package:countdowns/widgets/countdown_card_builder.dart';
import 'package:countdowns/widgets/date_picker_cupertino_modal.dart';
import 'package:countdowns/widgets/font_picker_material_modal.dart';
import 'package:countdowns/widgets/icon_picker_material_modal.dart';
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
  Color? _backgroundColor;
  IconData? _icon;
  String? _fontFamily;
  String? _fontDisplayName;
  Color? _contentColor;

  late FocusNode _focusNode;

  final _rowHeight = 42.0;

  final _modalShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Add Countdown'),
        actions: [
          TextButton(
            onPressed: () {
              var trimmed = _textBox.trim();
              if (trimmed.isNotEmpty && _dateTime != null) {
                CountdownEvent event = CountdownEvent(
                  title: _textBox,
                  eventDate: _dateTime!,
                  backgroundColor: _backgroundColor,
                  icon: _icon,
                  fontFamily: _fontFamily,
                  contentColor: _contentColor,
                );

                context.read<CountdownsProvider>()
                  ..addEvent(event)
                  ..sortEvents(
                    context.read<SettingsProvider>().settings.sortingMethod,
                  );
                Navigator.pop(context);
              } else {
                var snackBar = const SnackBar(
                  content: Text('A name and date are required'),
                  duration: Duration(seconds: 2),
                  //action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
            padding:
                const EdgeInsets.symmetric(horizontal: 15.0, vertical: 0.0),
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Hero(
                tag: 'emptycard',
                child: CountdownCardBuilder(
                  title: _textBox,
                  eventDate: _dateTime,
                  color: _backgroundColor,
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
                  onTap: () => showCupertinoModalPopup(
                    context: context,
                    builder: (context) => DatePickerCupertinoModal(
                      dateTime: _dateTime,
                      dateTimeCallback: (dateTime) => setState(
                        () {
                          _dateTime = dateTime;
                        },
                      ),
                    ),
                  ),
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
                    // TODO: Fix Check Mark Box
                    builder: (context) => ColorPickerMaterialModal(
                      color: _backgroundColor,
                      colorCallback: (color) => setState(
                        () {
                          _backgroundColor = color;
                        },
                      ),
                    ),
                  ),
                  title: Text('Background Color'),
                  trailing: Icon(
                    Icons.circle,
                    color: _backgroundColor,
                  ),
                ),
                ListTile(
                  onTap: () => showModalBottomSheet(
                    isScrollControlled: true,
                    shape: _modalShape,
                    context: context,
                    builder: (context) => IconPickerMaterialModal(
                      icon: _icon,
                      iconCallback: (icon) => setState(
                        () {
                          _icon = icon;
                        },
                      ),
                    ),
                  ),
                  title: Text('Icon'),
                  trailing: _icon == null
                      ? Icon(Icons.chevron_right_rounded)
                      : Icon(_icon),
                ),
                ListTile(
                  onTap: () => showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    shape: _modalShape,
                    builder: (context) => FontPickerMaterialModal(
                      fontName: _fontFamily,
                      fontCallback: (
                        fontName,
                        fontDisplayName,
                      ) =>
                          setState(
                        () {
                          _fontFamily = fontName;
                          _fontDisplayName = fontDisplayName;
                        },
                      ),
                    ),
                  ),
                  title: Text('Font'),
                  trailing: _fontFamily == null
                      ? Text('Default')
                      : Text(_fontDisplayName!),
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
