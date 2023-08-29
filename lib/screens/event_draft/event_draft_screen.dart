import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/event.dart';
import 'package:countdowns/providers/event_provider.dart';

import 'package:countdowns/screens/event_draft/option_circle.dart';
import 'package:countdowns/screens/event_draft/options/background_container.dart';
import 'package:countdowns/screens/event_draft/options/font_container.dart';
import 'package:countdowns/screens/event_draft/options/name_and_date_container.dart';
import 'package:countdowns/screens/event_draft/options/icon_container.dart';
import 'package:countdowns/providers/settings_provider.dart';
import 'package:countdowns/widgets/event_square.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class EventDraftScreen extends StatefulWidget {
  const EventDraftScreen({super.key, this.eventKey});

  final String? eventKey;

  @override
  State<EventDraftScreen> createState() => _EventDraftScreenState();
}

class _EventDraftScreenState extends State<EventDraftScreen> {
  late Event _eventDraft;
  late Event _existingEvent;
  bool _newEvent = true;
  bool _shouldShakeName = false;

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
      setState(() {
        _eventDraft.title = _titleController.text;
      });
    });

    Event? event = context.read<EventProvider>().getEvent(widget.eventKey);

    if (event == null) {
      _eventDraft = Event(
        title: '',
        eventDateTime: DateTime.now().add(const Duration(days: 1)),
        allDayEvent: true,
      );
    } else {
      _newEvent = false;
      _existingEvent = event;
      _eventDraft = event.copy();
      _titleController.text = _eventDraft.title;
    }

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
        toolbarHeight: 55,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 10),
            child: OutlinedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  if (_newEvent) {
                    context.read<EventProvider>().addEvent(_eventDraft);
                  } else {
                    _existingEvent.update(_eventDraft);
                    context.read<EventProvider>().saveEvent(_existingEvent);
                  }
                  context.pop();
                } else {
                  setState(() {
                    _selectedOption = 0;
                    _shouldShakeName = !_shouldShakeName;
                  });
                }
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
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: Global.styles.containerCornerRadius,
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
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: EventSquare(
                  event: _eventDraft,
                ),
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
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).canvasColor,
              child: IndexedStack(
                index: _selectedOption,
                children: [
                  NameAndDateContainer(
                    controller: _titleController,
                    eventDateTime: _eventDraft.eventDateTime,
                    onDateTimeChanged: (value) => setState(() {
                      _eventDraft.eventDateTime = value;
                    }),
                    allDay: _eventDraft.allDayEvent,
                    onAllDayChanged: (value) => setState(() {
                      _eventDraft.allDayEvent = value;
                    }),
                    shouldShakeName: _shouldShakeName,
                  ),
                  BackgroundContainer(
                    selectedColor: _eventDraft.backgroundColor,
                    onColorChanged: (color) => setState(() {
                      _eventDraft.backgroundColor = color;
                    }),
                    gradient: _eventDraft.backgroundGradient,
                    onGradientChanged: (shouldBeGradient) => setState(() {
                      _eventDraft.backgroundGradient = shouldBeGradient;
                    }),
                  ),
                  IconContainer(
                    selectedIcon: _eventDraft.icon,
                    onIconChanged: (value) => setState(
                      () {
                        if (value == _eventDraft.icon) {
                          _eventDraft.icon = null;
                          return;
                        }
                        _eventDraft.icon = value;
                      },
                    ),
                  ),
                  FontContainer(
                    fontFamily: _eventDraft.fontFamily ?? 'Default',
                    onFontSelected: (fontFamily) => setState(
                      () {
                        _eventDraft.fontFamily = fontFamily;
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
