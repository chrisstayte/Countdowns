import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Soft shadow under white text on photos.
const photoTextShadow = [
  Shadow(color: Color(0x59000000), blurRadius: 8, offset: Offset(0, 1)),
];

enum ScrimStyle {
  /// Even darkening, a little stronger at the bottom (cards, widgets).
  card,

  /// Dark at the top for the header, clear in the middle, dark at the bottom.
  fullBleed,
}

/// Paints an event's background: its colour, gradient (in its direction),
/// or photo (cropped for [shape], darkened, with a scrim).
class CountdownSurface extends StatelessWidget {
  const CountdownSurface({
    super.key,
    required this.event,
    required this.child,
    this.shape = CropShape.card,
    this.borderRadius = BorderRadius.zero,
    this.padding = EdgeInsets.zero,
    this.scrim = ScrimStyle.card,
    this.boxShadow,
  });

  final Countdown event;
  final Widget child;
  final CropShape shape;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final ScrimStyle scrim;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final photo = event.photoPath;
    final file = photo != null && PhotoStore.ready
        ? PhotoStore.instance.fileFor(photo)
        : null;
    final decoration = BoxDecoration(
      color: event.color,
      gradient: event.backgroundGradient,
      borderRadius: borderRadius,
      boxShadow: boxShadow,
    );
    if (file == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }
    final a = event.photoDarken;
    final scrimGradient = switch (scrim) {
      ScrimStyle.card => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.scrim.withValues(alpha: a),
          AppColors.scrim.withValues(alpha: (a + 0.15).clamp(0, 1)),
        ],
      ),
      ScrimStyle.fullBleed => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        stops: const [0, 0.35, 0.55, 1],
        colors: [
          AppColors.scrim.withValues(alpha: (a + 0.1).clamp(0, 1)),
          AppColors.scrim.withValues(alpha: a * 0.15),
          AppColors.scrim.withValues(alpha: a * 0.6),
          AppColors.scrim.withValues(alpha: (a + 0.4).clamp(0, 1)),
        ],
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: Image.file(
                file,
                fit: BoxFit.cover,
                alignment:
                    event.photoCrops?.alignmentFor(shape) ?? Alignment.center,
                cacheWidth: shape == CropShape.card ? 600 : null,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => DecoratedBox(decoration: decoration),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: scrimGradient),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
