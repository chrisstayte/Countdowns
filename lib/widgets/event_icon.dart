import 'package:countdowns/models/event_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// One of the redrawn event icons, tinted to [color].
class EventIcon extends StatelessWidget {
  const EventIcon(this.slug, {super.key, this.size = 24, required this.color});

  final String? slug;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final info = iconInfo(slug);
    if (info == null) return SizedBox.square(dimension: size);
    return Semantics(
      label: info.label,
      child: SvgPicture.asset(
        info.asset,
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color),
      ),
    );
  }
}
