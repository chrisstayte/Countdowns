import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:countdowns/fonts/font_library.dart';
import 'package:countdowns/models/art_catalog.dart';
import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/models/event_icons.dart';
import 'package:countdowns/providers/home_provider.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/art_painter.dart';
import 'package:countdowns/widgets_bridge/widget_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;

/// How many upcoming countdowns the widgets can see.
const widgetEventLimit = 12;

const _channel = MethodChannel('countdowns/widgets');

/// The folder the widgets read from (the App Group container on iOS, the
/// app's files dir on Android), or null where there are no widgets.
Future<String?> widgetContainerPath() async {
  if (!WidgetSnapshotWriter.supported) return null;
  try {
    final root = await _channel.invokeMethod<String>('containerPath');
    return root == null ? null : p.join(root, 'widget');
  } catch (_) {
    return null;
  }
}

String _hex(ui.Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Icon PNG for an event, tinted to its text colour.
String iconFileName(String slug, ui.Color tint) =>
    'icons/$slug-${_hex(tint).substring(1)}.png';

/// Photo PNG for an event, cropped for [shape]. The name changes whenever
/// the photo or crop does, so widgets never show a stale copy.
String photoFileName(Countdown e, CropShape shape) {
  final a = e.photoCrops?.pointFor(shape);
  final key = Object.hash(
    e.photoPath,
    a?.x,
    a?.y,
    a?.zoom,
  ).toUnsigned(32).toRadixString(16);
  return 'photos/${e.id}-${shape.name}-$key.png';
}

/// Bump when the art painter changes, so widgets redraw their copies.
const artRenderVersion = 1;

/// Widget images for drawn art, by snapshot key: the logical size it is
/// drawn at (about the widget's size in points, so motifs match the app)
/// and the pixel ratio of the PNG.
const artShapes = {
  'photo': (ui.Size(170, 170), 3.0),
  'photoWide': (ui.Size(360, 168), 2.5),
  'photoFull': (ui.Size(360, 376), 2.5),
};

/// PNG for drawn art in one widget shape. Shared by every countdown that
/// uses the same art.
String artFileName(Art art, String shapeKey) =>
    'photos/art-${art.id}-$shapeKey-v$artRenderVersion.png';

/// The JSON the home screen widgets read (WidgetKit on iOS, Glance on
/// Android). Widgets compute the count from
/// `target` themselves, so the snapshot only changes when events do.
Map<String, Object?> buildWidgetSnapshot(List<Countdown> events, DateTime now) {
  final upcoming = splitEvents(events, now).upcoming.take(widgetEventLimit);
  return {
    'version': 1,
    'updatedAt': now.toUtc().toIso8601String(),
    'events': [
      for (final e in upcoming)
        {
          'id': e.id,
          // What a tap on this countdown opens (see widget_links.dart).
          'link': e.id == null ? null : widgetLinkFor(e.id!).toString(),
          'title': e.title,
          // Seconds since the epoch of the next occurrence.
          'target': e.nextOccurrence(now).millisecondsSinceEpoch ~/ 1000,
          'allDay': e.allDay,
          'yearly': e.repeat == RepeatRule.yearly,
          'unit': e.unit.name,
          'font': canonicalEventFont(e.fontFamily),
          // A Google font travels as its file, installed by the writer
          // (see FontLibrary). Missing until it has downloaded: the widget
          // shows Default.
          'fontFile': isGoogleEventFont(e.fontFamily)
              ? FontLibrary.widgetPath(canonicalEventFont(e.fontFamily))
              : null,
          'text': _hex(e.textColor),
          'colors': [
            for (final c in e.art != null ? [e.color] : e.gradient ?? [e.color])
              _hex(c),
          ],
          'direction': e.direction.name,
          'icon': e.iconSlug == null
              ? null
              : iconFileName(e.iconSlug!, e.textColor),
          // Drawn art travels as images too, without the photo scrim.
          'photo': e.art != null
              ? artFileName(e.art!, 'photo')
              : e.hasPhoto
              ? photoFileName(e, CropShape.card)
              : null,
          'photoWide': e.art != null
              ? artFileName(e.art!, 'photoWide')
              : e.hasPhoto
              ? photoFileName(e, CropShape.wide)
              : null,
          // The large widget's single-countdown hero uses the full crop.
          'photoFull': e.art != null
              ? artFileName(e.art!, 'photoFull')
              : e.hasPhoto
              ? photoFileName(e, CropShape.full)
              : null,
          'darken': e.photoDarken,
          // False for drawn art: no darkening and no text shadow.
          'scrim': e.art == null,
          'createdAt': (e.createdAt ?? now).millisecondsSinceEpoch ~/ 1000,
        },
    ],
  };
}

/// Writes the snapshot, icon and photo copies where the widgets can read
/// them, then asks them to redraw. One writer for both platforms: the
/// native side of the `countdowns/widgets` channel says where to write
/// (the App Group container on iOS, the app's files dir on Android).
/// Quietly does nothing on other platforms.
class WidgetSnapshotWriter {
  WidgetSnapshotWriter({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get _supported => supported;

  Future<void>? _running;
  bool _again = false;
  List<Countdown> _latest = const [];

  /// Writes the last events again, for when something they show (a font
  /// that finished downloading) has changed.
  Future<void> refresh() => write(_latest);

  /// Coalesces bursts of changes into one write at a time.
  Future<void> write(List<Countdown> events) async {
    if (!_supported) return;
    _latest = events;
    if (_running != null) {
      _again = true;
      return _running;
    }
    _running = _loop();
    await _running;
    _running = null;
  }

  Future<void> _loop() async {
    do {
      _again = false;
      await _writeOnce(_latest);
    } while (_again);
  }

  Future<void> _writeOnce(List<Countdown> events) async {
    try {
      final root = await _channel.invokeMethod<String>('containerPath');
      if (root == null) return;
      final dir = Directory(p.join(root, 'widget'));
      await Directory(p.join(dir.path, 'icons')).create(recursive: true);
      await Directory(p.join(dir.path, 'photos')).create(recursive: true);
      final snapshot = buildWidgetSnapshot(events, _clock());
      final byId = {for (final e in events) e.id: e};
      final keep = <String>{};
      final fonts = FontLibrary.instance;
      for (final entry in snapshot['events']! as List) {
        final m = entry as Map<String, Object?>;
        final e = byId[m['id']]!;
        if (m['fontFile'] != null) {
          final family = m['font']! as String;
          // Offline is fine: the widget uses Default, and the library
          // asks for another write once the file arrives.
          try {
            await fonts.use(family).timeout(const Duration(seconds: 20));
          } catch (_) {}
          if (await fonts.installedFile(family) == null) m['fontFile'] = null;
        }
        if (m['icon'] case final String icon) {
          keep.add(icon);
          await _renderIcon(File(p.join(dir.path, icon)), e);
        }
        for (final (key, shape, width) in [
          ('photo', CropShape.card, 600),
          ('photoWide', CropShape.wide, 900),
          ('photoFull', CropShape.full, 700),
        ]) {
          if (m[key] case final String photo) {
            keep.add(photo);
            final out = File(p.join(dir.path, photo));
            if (e.art case final art?) {
              final (size, ratio) = artShapes[key]!;
              await _renderArt(out, art, size, ratio);
            } else {
              await _renderPhoto(out, e, shape, width);
            }
          }
        }
      }
      await _prune(Directory(p.join(dir.path, 'icons')), dir.path, keep);
      await _prune(Directory(p.join(dir.path, 'photos')), dir.path, keep);
      // Fonts stay installed for every countdown, not just the ones the
      // widgets can see, so opening any countdown never downloads.
      await fonts.prune({
        for (final e in events)
          if (isGoogleEventFont(e.fontFamily)) canonicalEventFont(e.fontFamily),
      });
      final tmp = File(p.join(dir.path, 'snapshot.json.tmp'));
      await tmp.writeAsString(jsonEncode(snapshot));
      await tmp.rename(p.join(dir.path, 'snapshot.json'));
      await _channel.invokeMethod<void>('reload');
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'widget snapshot',
        ),
      );
    }
  }

  Future<void> _prune(Directory d, String root, Set<String> keep) async {
    await for (final f in d.list()) {
      if (!keep.contains(p.relative(f.path, from: root))) await f.delete();
    }
  }

  Future<void> _renderIcon(File out, Countdown e) async {
    if (await out.exists()) return;
    final info = iconInfo(e.iconSlug);
    if (info == null) return;
    final svg = await rootBundle.loadString(info.asset);
    final loaded = await vg.loadPicture(
      SvgStringLoader(svg, theme: SvgTheme(currentColor: e.textColor)),
      null,
    );
    const size = 96;
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..scale(size / loaded.size.width)
      ..drawPicture(loaded.picture);
    loaded.picture.dispose();
    final image = await recorder.endRecording().toImage(size, size);
    await _writePng(out, image);
  }

  Future<void> _renderPhoto(
    File out,
    Countdown e,
    CropShape shape,
    int width,
  ) async {
    if (await out.exists() || !PhotoStore.ready) return;
    final source = PhotoStore.instance.fileFor(e.photoPath!);
    if (!await source.exists()) return;
    final codec = await ui.instantiateImageCodec(await source.readAsBytes());
    final src = (await codec.getNextFrame()).image;
    final height = (width / shape.aspect).round();
    // Same maths as the app: BoxFit.cover at the alignment, then zoom.
    final crop = cropRectIn(
      ui.Size(src.width.toDouble(), src.height.toDouble()),
      shape.aspect,
      e.photoCrops?.pointFor(shape) ?? CropPoint.center,
    );
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      src,
      crop,
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    final image = await recorder.endRecording().toImage(width, height);
    src.dispose();
    await _writePng(out, image);
  }

  Future<void> _renderArt(File out, Art art, ui.Size size, double ratio) async {
    if (await out.exists()) return;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..scale(ratio);
    paintArt(canvas, size, art);
    final image = await recorder.endRecording().toImage(
      (size.width * ratio).round(),
      (size.height * ratio).round(),
    );
    await _writePng(out, image);
  }

  Future<void> _writePng(File out, ui.Image image) async {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes != null) await out.writeAsBytes(bytes.buffer.asUint8List());
  }
}
