import 'package:audioplayers/audioplayers.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/models/palette.dart';
import 'package:countdowns/providers/event_draft_provider.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/screens/event_form/option_circle.dart';
import 'package:countdowns/screens/event_form/options/background/background_container.dart';
import 'package:countdowns/screens/event_form/options/font_container.dart';
import 'package:countdowns/screens/event_form/options/name_and_date/name_and_date_container.dart';
import 'package:countdowns/screens/event_form/options/icon_container.dart';
import 'package:countdowns/widgets/event_container.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.eventKey});

  final String? eventKey;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  late final DraftSession _session;
  bool _saving = false;
  bool _shouldShakeName = false;
  bool _isSquare = true;

  int _selectedOption = 0;
  late final TextEditingController _titleController;

  void _selectOption(int index) {
    var settings = ref.read(localSettingsProvider);
    if (settings.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    if (settings.soundEffects) {
      AudioPlayer().play(
        AssetSource('sounds/select.mp3'),
        mode: PlayerMode.lowLatency,
      );
    }
    setState(() {
      _selectedOption = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _session = DraftSession(widget.eventKey);
    _titleController = TextEditingController(
      text: ref.read(eventDraftProvider(_session)).title,
    );
    _titleController.addListener(() {
      ref
          .read(eventDraftProvider(_session).notifier)
          .change((d) => d.copyWith(title: _titleController.text));
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(eventDraftProvider(_session));
    final editor = ref.read(eventDraftProvider(_session).notifier);
    if (widget.eventKey != null &&
        ref.watch(eventByIdProvider(widget.eventKey)) == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Event Not Found')),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 55,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            var settings = ref.read(localSettingsProvider);
            if (settings.hapticFeedback) {
              HapticFeedback.lightImpact();
            }
            if (settings.soundEffects) {
              AudioPlayer().play(
                AssetSource('sounds/tap.mp3'),
                ctx: AudioContext(
                  iOS: AudioContextIOS(
                    category: AVAudioSessionCategory.ambient,
                  ),
                ),
                mode: PlayerMode.lowLatency,
              );
            }
            context.pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: OutlinedButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_saving) return;
                      if (_titleController.text.isNotEmpty) {
                        setState(() => _saving = true);
                        try {
                          await ref
                              .read(eventsControllerProvider)
                              .save(ref.read(eventDraftProvider(_session)));
                        } catch (error) {
                          if (!context.mounted) return;
                          setState(() => _saving = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not save countdown: $error'),
                            ),
                          );
                          return;
                        }
                        if (!context.mounted) return;
                        var settings = ref.read(localSettingsProvider);
                        if (settings.hapticFeedback) {
                          HapticFeedback.lightImpact();
                        }
                        if (settings.soundEffects) {
                          AudioPlayer().play(
                            AssetSource('sounds/success.mp3'),
                            ctx: AudioContext(
                              iOS: AudioContextIOS(
                                category: AVAudioSessionCategory.ambient,
                              ),
                            ),
                            mode: PlayerMode.lowLatency,
                          );
                        }

                        context.pop();
                      } else {
                        setState(() {
                          _selectedOption = 0;
                          _shouldShakeName = !_shouldShakeName;
                          if (ref.read(localSettingsProvider).hapticFeedback) {
                            HapticFeedback.vibrate();
                          }
                          if (ref.read(localSettingsProvider).soundEffects) {
                            AudioPlayer().play(
                              AssetSource('sounds/error.mp3'),
                              ctx: AudioContext(
                                iOS: AudioContextIOS(
                                  category: AVAudioSessionCategory.ambient,
                                ),
                              ),
                              mode: PlayerMode.lowLatency,
                            );
                          }
                        });
                      }
                    },
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                backgroundColor: WidgetStateProperty.all<Color>(
                  Global.colors.offColor,
                ),
                side: WidgetStateProperty.all<BorderSide>(
                  BorderSide(color: Global.colors.offColor),
                ),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: Global.styles.containerCornerRadius,
                  ),
                ),
                elevation: WidgetStateProperty.all<double>(2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded),
                  SizedBox(width: 5),
                  Text('Save'),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (!_isSquare) {
                            var settings = ref.read(localSettingsProvider);
                            if (settings.hapticFeedback) {
                              HapticFeedback.lightImpact();
                            }
                            if (settings.soundEffects) {
                              AudioPlayer().play(
                                AssetSource('sounds/select.mp3'),
                                ctx: AudioContext(
                                  iOS: AudioContextIOS(
                                    category: AVAudioSessionCategory.ambient,
                                  ),
                                ),
                                mode: PlayerMode.lowLatency,
                              );
                            }
                            setState(() {
                              _isSquare = true;
                            });
                          }
                        },
                        child: Text(
                          'Small',
                          style: TextStyle(
                            fontWeight: _isSquare ? FontWeight.bold : null,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      GestureDetector(
                        onTap: () {
                          if (_isSquare) {
                            var settings = ref.read(localSettingsProvider);
                            if (settings.hapticFeedback) {
                              HapticFeedback.lightImpact();
                            }
                            if (settings.soundEffects) {
                              AudioPlayer().play(
                                AssetSource('sounds/select.mp3'),
                                ctx: AudioContext(
                                  iOS: AudioContextIOS(
                                    category: AVAudioSessionCategory.ambient,
                                  ),
                                ),
                                mode: PlayerMode.lowLatency,
                              );
                            }
                            setState(() {
                              _isSquare = false;
                            });
                          }
                        },
                        child: Text(
                          'Large',
                          style: TextStyle(
                            fontWeight: !_isSquare ? FontWeight.bold : null,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isSquare ? 0 : 15,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: _isSquare ? 169 : 500,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: Global.styles.containerCornerRadius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(
                            alpha: 0.5,
                          ), // Shadow color
                          spreadRadius: 2, // Spread radius
                          blurRadius: 25, // Blur radius
                          offset: const Offset(
                            0,
                            3,
                          ), // changes position of shadow
                        ),
                      ],
                    ),
                    child: EventContainer(event: draft),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 50),
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
              color: Theme.of(context).cardColor,
              child: IndexedStack(
                index: _selectedOption,
                children: [
                  NameAndDateContainer(
                    eventKey: widget.eventKey,
                    controller: _titleController,
                    eventDateTime: draft.dateTime,
                    onDateTimeChanged: (value) =>
                        editor.change((d) => d.copyWith(dateTime: value)),
                    allDay: draft.allDay,
                    onAllDayChanged: (value) =>
                        editor.change((d) => d.copyWith(allDay: value)),
                    shouldShakeName: _shouldShakeName,
                  ),
                  BackgroundContainer(
                    selectedColor: draft.color,
                    onColorChanged: (color) =>
                        editor.change((d) => d.copyWith(colorArgb: color.toARGB32())),
                    gradient: draft.gradientId != null,
                    onGradientChanged: (shouldBeGradient) => editor.change(
                      (d) => d.copyWith(
                        gradientId: shouldBeGradient ? 'legacy' : null,
                        gradientDirection: shouldBeGradient
                            ? GradientDirection.diagonalDown
                            : null,
                      ),
                    ),
                  ),
                  IconContainer(
                    selectedIcon: eventIcons
                        .where(
                          (i) =>
                              i.codePoint ==
                              iconInfo(draft.iconSlug)?.legacyCodePoint,
                        )
                        .firstOrNull,
                    onIconChanged: (value) => editor.change(
                      (d) => d.copyWith(
                        iconSlug: slugForCodePoint(value?.codePoint) ==
                                d.iconSlug
                            ? null
                            : slugForCodePoint(value?.codePoint),
                      ),
                    ),
                  ),
                  FontContainer(
                    fontFamily: draft.fontFamily,
                    onFontSelected: (fontFamily) =>
                        editor.change((d) => d.copyWith(fontFamily: fontFamily)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
