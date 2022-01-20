import 'package:countdowns/global.dart/global.dart';
import 'package:countdowns/models/countdown_event.dart';
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

class EditCountdownPage extends StatefulWidget {
  const EditCountdownPage({Key? key, required this.countdownEvent})
      : super(key: key);

  final CountdownEvent countdownEvent;

  @override
  _EditCountdownPageState createState() => _EditCountdownPageState();
}

class _EditCountdownPageState extends State<EditCountdownPage> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();

  String _textBox = '';
  late DateTime _dateTime;
  Color? _backgroundColor;
  IconData? _icon;
  String? _fontFamily;
  String? _fontDisplayName;
  Color? _contentColor;

  final _modalShape = const RoundedRectangleBorder(
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(10),
      topRight: Radius.circular(10),
    ),
  );

  @override
  void initState() {
    _textEditingController.text = widget.countdownEvent.title;
    _textBox = widget.countdownEvent.title;
    _dateTime = widget.countdownEvent.eventDate;
    _backgroundColor = widget.countdownEvent.backgroundColor;
    _icon = widget.countdownEvent.icon;
    _contentColor = widget.countdownEvent.contentColor;
    _fontFamily = widget.countdownEvent.fontFamily;
    _fontDisplayName = Global.fonts.fontMap[widget.countdownEvent.fontFamily];

    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Countdown'),
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
              var trimmed = _textBox.trim();
              if (trimmed.isNotEmpty && _dateTime != null) {
                widget.countdownEvent.title = _textBox;
                widget.countdownEvent.eventDate = _dateTime;
                widget.countdownEvent.icon = _icon;
                widget.countdownEvent.backgroundColor = _backgroundColor;
                widget.countdownEvent.contentColor = _contentColor;
                widget.countdownEvent.fontFamily = _fontFamily;
                context
                    .read<CountdownsProvider>()
                    .editEvent(widget.countdownEvent);
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
            child: Text(
              'Save',
            ),
          )
        ],
      ),
      body: Column(
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
                          controller: _textEditingController,
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
                  // onTap: () => _showDatePicker(),
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
                          '${_dateTime.month.toString()}/${_dateTime.day.toString()}/${_dateTime.year.toString()}'),
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
