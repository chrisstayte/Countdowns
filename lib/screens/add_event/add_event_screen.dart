import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/add_event/event_square_constructor.dart';
import 'package:countdowns/screens/add_event/option_circle.dart';
import 'package:countdowns/screens/add_event/options/background_container.dart';
import 'package:countdowns/screens/add_event/options/font_container.dart';
import 'package:countdowns/screens/add_event/options/name_and_date_container.dart';
import 'package:countdowns/screens/add_event/options/icon_container.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddEventScreen extends StatefulWidget {
  AddEventScreen({super.key, this.eventKey});

  String? eventKey;

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  late DateTime _eventDateTime;
  late bool _allDay;
  IconData? _selectedIcon;
  String? _fontFamily;

  int _selectedOption = 0;
  final TextEditingController _titleController = TextEditingController();

  void _selectOption(int index) {
    if (context.read<SettingsProvider>().settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _selectedOption = index;
    });
  }

  @override
  void initState() {
    _titleController.addListener(() {
      setState(() {});
    });

    _eventDateTime = DateTime.now();
    _allDay = true;

    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: OutlinedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  Event newEvent = Event(
                    title: _titleController.text,
                    icon: _selectedIcon,
                    fontFamily: _fontFamily,
                    eventDate: _eventDateTime,
                    allDayEvent: _allDay,
                  );

                  context.read<EventProvider>().addEvent(newEvent);
                }
                context.pop();
              },
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(
                  Colors.white,
                ),
                backgroundColor: MaterialStateProperty.all<Color>(
                  Global.colors.offColor,
                ),
                side: MaterialStateProperty.all<BorderSide>(
                  BorderSide(
                    color: Global.colors.offColor,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded),
                  SizedBox(width: 5),
                  Text('Save'),
                ],
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: EventSquareConstructor(
                      title: _titleController.text,
                      icon: _selectedIcon,
                      fontFamily: _fontFamily,
                      eventDateTime: _eventDateTime,
                      allDay: _allDay,
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 63,
                  color: Theme.of(context).scaffoldBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        GestureDetector(
                          onTap: () => _selectOption(0),
                          child: OptionCircle(
                            selected: _selectedOption == 0,
                            icon: Icons.calendar_month,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectOption(1),
                          child: OptionCircle(
                            selected: _selectedOption == 1,
                            icon: Icons.palette_rounded,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectOption(2),
                          child: OptionCircle(
                            icon: Icons.add_reaction_rounded,
                            selected: _selectedOption == 2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _selectOption(3),
                          child: OptionCircle(
                            selected: _selectedOption == 3,
                            icon: Icons.font_download_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
              child: Container(
            color: Theme.of(context).canvasColor,
            child: IndexedStack(
              index: _selectedOption,
              children: [
                NameAndDateContainer(
                  controller: _titleController,
                  eventDateTime: _eventDateTime,
                  onDateTimeChanged: (value) => setState(() {
                    _eventDateTime = value;
                  }),
                  allDay: _allDay,
                  onAllDayChanged: (value) => setState(() {
                    _allDay = value;
                  }),
                ),
                BackgroundContainer(),
                IconContainer(
                  selectedIcon: _selectedIcon,
                  onIconChanged: (value) => setState(() {
                    if (value == _selectedIcon) {
                      _selectedIcon = null;
                      return;
                    }
                    _selectedIcon = value;
                  }),
                ),
                FontContainer(
                  fontFamily: _fontFamily,
                  onFontSelected: (fontFamily) => setState(() {
                    _fontFamily = fontFamily;
                  }),
                )
              ],
            ),
          ))
        ],
      ),
    );
  }
}
