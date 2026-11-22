import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/utilities/count_format.dart';
import 'package:countdowns/widgets/countdown_surface.dart';
import 'package:countdowns/widgets/event_icon.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// The live preview card at the top of the editor.
class EditorPreview extends StatelessWidget {
  const EditorPreview({
    super.key,
    required this.draft,
    required this.now,
    this.onCrop,
    this.height = 150,
    this.shape = CropShape.card,
  });

  final Countdown draft;
  final DateTime now;
  final VoidCallback? onCrop;
  final double height;
  final CropShape shape;

  @override
  Widget build(BuildContext context) {
    final ink = draft.textColor;
    final shadows = draft.hasPhoto ? photoTextShadow : null;
    final count = cardCount(draft, now);
    final when = draft.allDay
        ? DateFormat('EEE, MMM d').format(draft.dateTime)
        : DateFormat('EEE, MMM d · h:mm a').format(draft.dateTime);
    final title = draft.title.isEmpty ? 'Name your countdown' : draft.title;
    return Semantics(
      label: 'Preview: $title, ${count.big} ${count.unit}',
      child: SizedBox(
        height: height,
        child: CountdownSurface(
          event: draft,
          shape: shape,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E1C1633),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: resolveEventFont(draft.fontFamily),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                            color: draft.title.isEmpty
                                ? ink.withValues(alpha: 0.55)
                                : ink,
                            shadows: shadows,
                          ),
                        ),
                      ),
                      if (draft.iconSlug != null)
                        EventIcon(draft.iconSlug, size: 26, color: ink),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        count.big,
                        style: AppText.numeral(
                          54,
                          color: ink,
                        ).copyWith(shadows: shadows),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        count.unit,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ink,
                          shadows: shadows,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          when,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ink,
                            shadows: shadows,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (draft.hasPhoto && onCrop != null)
                Positioned(
                  right: -4,
                  top: 34,
                  child: Semantics(
                    button: true,
                    label: 'Crop photo',
                    child: GestureDetector(
                      onTap: onCrop,
                      child: Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.crop_rounded,
                              size: 14,
                              color: AppColors.ink,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Crop',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
