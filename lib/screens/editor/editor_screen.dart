import 'package:countdowns/constants.dart';
import 'package:countdowns/models/background_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_draft_provider.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/notification_provider.dart';
import 'package:countdowns/providers/recents_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/editor/editor_details.dart';
import 'package:countdowns/screens/editor/editor_look.dart';
import 'package:countdowns/screens/editor/editor_preview.dart';
import 'package:countdowns/screens/editor/photo_flow.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/feedback.dart';
import 'package:countdowns/widgets/ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

enum EditorTab { details, look }

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key, this.eventKey, this.title, this.date});

  final String? eventKey;
  final String? title;
  final DateTime? date;

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  late final DraftSession _session = DraftSession(
    widget.eventKey,
    title: widget.title,
    date: widget.date,
  );
  late final TextEditingController _title;
  late final int? _originalColor;
  EditorTab _tab = EditorTab.details;
  bool _saving = false;
  bool _nameError = false;

  bool get _isNew => widget.eventKey == null;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(eventDraftProvider(_session));
    _originalColor = _isNew ? null : draft.colorArgb;
    _title = TextEditingController(text: draft.title)
      ..addListener(() {
        if (_nameError && _title.text.trim().isNotEmpty) {
          setState(() => _nameError = false);
        }
        _edit((d) => d.copyWith(title: _title.text));
      });
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _edit(Countdown Function(Countdown) change) =>
      ref.read(eventDraftProvider(_session).notifier).change(change);

  Future<void> _save() async {
    if (_saving) return;
    final draft = ref.read(eventDraftProvider(_session));
    if (draft.title.trim().isEmpty) {
      feedback(ref, Sound.error);
      setState(() {
        _nameError = true;
        _tab = EditorTab.details;
      });
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    var reminderNote = false;
    if (draft.reminders.isNotEmpty && !ref.read(localSettingsProvider).notify) {
      final notifications = ref.read(notificationsProvider);
      if (notifications.supported && await notifications.requestPermission()) {
        await ref.read(localSettingsProvider.notifier).setNotify(true);
      } else {
        reminderNote = true;
      }
    }
    final int id;
    try {
      id = await ref
          .read(eventsControllerProvider)
          .save(draft.copyWith(title: draft.title.trim()));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Couldn’t save this countdown: $error')),
      );
      return;
    }
    final recents = ref.read(recentsProvider.notifier);
    if (draft.iconSlug != null) await recents.useIcon(draft.iconSlug!);
    await recents.useFont(draft.fontFamily);
    if (draft.photoPath != null) await recents.usePhoto(draft.photoPath!);
    if (!draft.hasPhoto) await recents.useBackground(backgroundKeyOf(draft));
    feedback(ref, Sound.success);
    if (reminderNote) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Reminders are saved. Turn on notifications in Settings to get them.',
          ),
        ),
      );
    }
    if (!mounted) return;
    if (_isNew) {
      context.pushReplacementNamed(
        AppRoutes.event,
        pathParameters: {'id': '$id'},
      );
    } else {
      context.pop();
    }
  }

  Future<void> _delete() async {
    feedback(ref);
    final draft = ref.read(eventDraftProvider(_session));
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete “${draft.title}”?'),
        content: const Text('This can’t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || draft.id == null) return;
    feedback(ref, Sound.trash);
    await ref.read(eventsControllerProvider).deleteEvent(draft.id!);
    if (mounted) context.goNamed(AppRoutes.home);
  }

  Future<void> _addPhoto() async {
    feedback(ref);
    final draft = ref.read(eventDraftProvider(_session));
    final result = await pickAndCropPhoto(context, draft);
    if (result != null) {
      _edit(
        (d) => d.copyWith(
          photoPath: result.path,
          photoCrops: result.crops,
          gradientId: null,
          gradientDirection: null,
        ),
      );
    }
  }

  Future<void> _crop() async {
    feedback(ref);
    final draft = ref.read(eventDraftProvider(_session));
    final crops = await cropPhoto(context, draft);
    if (crops != null) _edit((d) => d.copyWith(photoCrops: crops));
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(eventDraftProvider(_session));
    final now = ref.watch(minuteClockProvider);
    if (!_isNew && ref.watch(eventByIdProvider(widget.eventKey)) == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('This countdown was deleted.')),
      );
    }
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Row(
        children: [
          TextAction('Cancel', onTap: () => context.pop()),
          Expanded(
            child: Text(
              _isNew ? 'New countdown' : 'Edit countdown',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
          ),
          PillButton(
            label: 'Save',
            background: AppColors.highlighter,
            foreground: AppColors.ink,
            border: AppColors.ink,
            onTap: _saving ? null : _save,
          ),
        ],
      ),
    );
    final details = EditorDetails(
      draft: draft,
      edit: _edit,
      titleController: _title,
      nameError: _nameError,
      onDelete: _isNew ? null : _delete,
    );
    final look = EditorLook(
      draft: draft,
      edit: _edit,
      onAddPhoto: _addPhoto,
      originalColor: _originalColor,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _TabletEditor(
                  header: header,
                  draft: draft,
                  now: now,
                  details: details,
                  look: EditorLook(
                    draft: draft,
                    edit: _edit,
                    onAddPhoto: _addPhoto,
                    originalColor: _originalColor,
                    backgroundColumns: 6,
                    iconColumns: 8,
                  ),
                  onCrop: _crop,
                );
              }
              return Column(
                children: [
                  header,
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                    child: EditorPreview(draft: draft, now: now, onCrop: _crop),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: PillSegmented<EditorTab>(
                      values: EditorTab.values,
                      selected: _tab,
                      label: (t) => t == EditorTab.details ? 'Details' : 'Look',
                      height: 38,
                      fontSize: 15,
                      onChanged: (t) {
                        feedback(ref, Sound.select, false);
                        FocusScope.of(context).unfocus();
                        setState(() => _tab = t);
                      },
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          30 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: _tab == EditorTab.details ? details : look,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// iPad: live preview on the left, Details and Look side by side.
class _TabletEditor extends StatelessWidget {
  const _TabletEditor({
    required this.header,
    required this.draft,
    required this.now,
    required this.details,
    required this.look,
    required this.onCrop,
  });

  final Widget header;
  final Countdown draft;
  final DateTime now;
  final Widget details, look;
  final VoidCallback onCrop;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      header,
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionLabel('Card'),
                      const SizedBox(height: 10),
                      EditorPreview(
                        draft: draft,
                        now: now,
                        onCrop: onCrop,
                        height: 180,
                      ),
                      const SizedBox(height: 24),
                      const SectionLabel('Widgets'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          SizedBox(
                            width: 140,
                            child: EditorPreview(
                              draft: draft,
                              now: now,
                              height: 140,
                              compact: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EditorPreview(
                        draft: draft,
                        now: now,
                        height: 140,
                        shape: CropShape.wide,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _Panel(title: 'Details', child: details),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _Panel(title: 'Look', child: look),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
    ),
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppText.sheetTitle),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
