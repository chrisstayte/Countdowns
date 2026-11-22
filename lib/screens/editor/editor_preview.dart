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
    this.compact = false,
  });

  /// Small widget size: smaller type and no date.
  final bool compact;

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
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E2E2A3A),
              blurRadius: 30,
              offset: Offset(0, 14),
            ),
          ],
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
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
                              fontFamilyFallback: eventFontFallback,
                              fontSize: compact ? 17 : 24,
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
                    if (compact)
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              count.big,
                              style: AppText.numeral(
                                40,
                                color: ink,
                              ).copyWith(shadows: shadows),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              count.unit,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: ink,
                                shadows: shadows,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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
                          if (!compact)
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
              ),
              // Inset from the card's own edge (not the content padding),
              // below the icon, so the whole pill is always visible.
              if (draft.hasPhoto && onCrop != null)
                Positioned(
                  right: 12,
                  top: 50,
                  child: Semantics(
                    button: true,
                    label: 'Crop photo',
                    child: GestureDetector(
                      onTap: onCrop,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
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
