import 'dart:io';

import 'package:countdowns/models/countdown.dart';
import 'package:material_ui/material_ui.dart';

/// Shows [file] filling its box the way a crop says: BoxFit.cover at the
/// crop's alignment, zoomed in by its zoom.
///
/// The image is laid out at zoom × the box size with BoxFit.cover and the
/// same alignment, then that larger box is aligned inside this one. The two
/// offsets add up to exactly the crop rectangle [cropRectIn] describes, so
/// no image size is needed.
class CroppedPhoto extends StatelessWidget {
  const CroppedPhoto({
    super.key,
    required this.file,
    required this.point,
    this.cacheWidth,
    this.errorBuilder,
  });

  final File file;
  final CropPoint point;
  final int? cacheWidth;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth * point.zoom, h = box.maxHeight * point.zoom;
      final image = Image.file(
        file,
        fit: BoxFit.cover,
        alignment: point.alignment,
        cacheWidth: cacheWidth == null
            ? null
            : (cacheWidth! * point.zoom).round(),
        gaplessPlayback: true,
        errorBuilder: errorBuilder,
      );
      if (point.zoom == 1) return image;
      return ClipRect(
        child: OverflowBox(
          alignment: point.alignment,
          minWidth: w,
          maxWidth: w,
          minHeight: h,
          maxHeight: h,
          child: image,
        ),
      );
    },
  );
}
