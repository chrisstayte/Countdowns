// Rebuild the store artwork from the shipping widgets and bundled brand assets:
// flutter test tool/store_assets_test.dart --reporter expanded
// swift tool/store-assets/opaque.swift store-assets/v3
// python3 tool/store-assets/package.py
//
// This is an export harness, kept outside test/ so normal CI does not regenerate
// marketing files. No production database, device account or network is used.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:countdowns/models/countdown.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/home_provider.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/editor/editor_screen.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/share/share_sheet.dart';
import 'package:countdowns/screens/tablet/wall_screen.dart';
import 'package:countdowns/storage/photos.dart';
import 'package:countdowns/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

const output = 'store-assets/v3';
final now = DateTime(2026, 11, 22, 9, 41);

class _Clock extends CountdownClock {
  @override
  DateTime build() => now;
}

class _Minute extends MinuteClock {
  @override
  DateTime build() => now;
}

List<Countdown> get examples => [
  Countdown(
    id: 1,
    title: 'Weekend away',
    dateTime: DateTime(2026, 12, 4),
    iconSlug: 'suitcase',
    photoPath: 'photos/weekend-away.png',
    photoDarken: 0.20,
    createdAt: DateTime(2026, 9, 1),
    reminders: const [0, 1440],
  ),
  Countdown(
    id: 2,
    title: 'Mia’s birthday',
    dateTime: DateTime(2027, 1, 3),
    iconSlug: 'cake',
    artId: 'birthday',
    unit: CountUnit.sleeps,
    repeat: RepeatRule.yearly,
    reminders: const [0, 1440, 10080],
  ),
  Countdown(
    id: 3,
    title: 'Japan trip',
    dateTime: DateTime(2027, 3, 15, 9, 30),
    allDay: false,
    iconSlug: 'plane',
    gradientId: 'lagoon',
    colorArgb: 0xFF66B6FE,
  ),
  Countdown(
    id: 4,
    title: 'Our wedding',
    dateTime: DateTime(2027, 5, 21),
    iconSlug: 'rings',
    artId: 'wash-rose',
    reminders: const [0, 10080],
  ),
  Countdown(
    id: 5,
    title: 'Graduation',
    dateTime: DateTime(2027, 6, 30),
    iconSlug: 'graduation',
    artId: 'confetti-night',
    unit: CountUnit.weeks,
  ),
  Countdown(
    id: 6,
    title: 'Started running',
    dateTime: DateTime(2026, 8, 14),
    kind: EventKind.since,
    iconSlug: 'running',
    artId: 'mountains',
    reminders: const [0],
  ),
  Countdown(
    id: 7,
    title: 'Together',
    dateTime: DateTime(2022, 7, 26),
    kind: EventKind.since,
    iconSlug: 'heart',
    gradientId: 'sunset',
  ),
  Countdown(
    id: 8,
    title: 'Our first home',
    dateTime: DateTime(2026, 8, 3),
    kind: EventKind.since,
    iconSlug: 'home',
    artId: 'gingham-sky',
  ),
  Countdown(
    id: 9,
    title: 'A year of me',
    dateTime: DateTime(2025, 11, 22),
    kind: EventKind.since,
    iconSlug: 'sparkle',
    colorArgb: 0xFF5FD3B5,
  ),
];

typedef Device = ({
  String path,
  Size size,
  double scale,
  TargetPlatform platform,
});
const devices = <Device>[
  (
    path: 'apple/iphone',
    size: Size(402, 874),
    scale: 3,
    platform: TargetPlatform.iOS,
  ),
  (
    path: 'apple/iphone-large',
    size: Size(440, 956),
    scale: 3,
    platform: TargetPlatform.iOS,
  ),
  (
    path: 'apple/iphone-face-id-large',
    size: Size(414, 896),
    scale: 3,
    platform: TargetPlatform.iOS,
  ),
  (
    path: 'apple/iphone-home-button-large',
    size: Size(414, 736),
    scale: 3,
    platform: TargetPlatform.iOS,
  ),
  (
    path: 'apple/ipad-13',
    size: Size(1376, 1032),
    scale: 2,
    platform: TargetPlatform.iOS,
  ),
  (
    path: 'google-play/phone',
    size: Size(405, 720),
    scale: 8 / 3,
    platform: TargetPlatform.android,
  ),
  (
    path: 'google-play/tablet-7',
    size: Size(1152, 648),
    scale: 5 / 3,
    platform: TargetPlatform.android,
  ),
  (
    path: 'google-play/tablet-10',
    size: Size(1280, 720),
    scale: 2,
    platform: TargetPlatform.android,
  ),
];
const slugs = [
  '01-soon',
  '02-since',
  '03-live-countdown',
  '04-make-it-yours',
  '05-reminders',
  '06-share-or-display',
  '07-background-library',
];
const headlines = [
  'Good days\nare coming.',
  'Look how far\nyou’ve come.',
  'Make the wait\npart of the fun.',
  'Your days.\nYour style.',
  'The date matters.\nRemember it.',
  'A little joy.\nWorth sharing.',
  'A different look\nfor every day.',
];
const subtitles = [
  'Count down to everything you’re looking forward to.',
  'Count up from the moments that changed your life.',
  'Days, weeks, sleeps, or hours. Find your kind of countdown.',
  'Mix colors, gradients, illustrations, icons, and fonts.',
  'Set reminders for the day, a day before, or a week ahead.',
  'Make a story, a square, or a calendar event.',
  'Photos, patterns, textures, illustrations, and more.',
];
const grounds = [
  AppColors.paper,
  AppColors.highlighter,
  Color(0xFFDDEEF5),
  Color(0xFFF4E7F5),
  Color(0xFFE0F2E9),
  AppColors.paper,
  Color(0xFFFBE9D8),
];

Future<void> loadFonts() async {
  for (final family in {
    'Inter': [
      'fonts/Inter-400.ttf',
      'fonts/Inter-500.ttf',
      'fonts/Inter-600.ttf',
      'fonts/Inter-700.ttf',
    ],
    'BricolageGrotesque': [
      'fonts/BricolageGrotesque-600.ttf',
      'fonts/BricolageGrotesque-700.ttf',
      'fonts/BricolageGrotesque-800.ttf',
    ],
    'BricolageDisplay': ['fonts/BricolageDisplay-800.ttf'],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      loader.addFont(
        File(file).readAsBytes().then((b) => ByteData.sublistView(b)),
      );
    }
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      File(
        '${File(Platform.resolvedExecutable).parent.parent.parent.path}/material_fonts/MaterialIcons-Regular.otf',
      ).readAsBytes().then((b) => ByteData.sublistView(b)),
    );
  await icons.load();
}

Future<void> warmPhoto() async {
  final file = PhotoStore.instance.fileFor('photos/weekend-away.png');
  for (final provider in <ImageProvider>[
    FileImage(file),
    ResizeImage(FileImage(file), width: 600),
  ]) {
    final ready = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (image, synchronous) {
        if (!ready.isCompleted) ready.complete();
      },
      onError: (Object error, StackTrace? stack) {
        if (!ready.isCompleted) ready.completeError(error, stack);
      },
    );
    stream.addListener(listener);
    await ready.future;
    stream.removeListener(listener);
  }
}

void textAt(
  Canvas c,
  String text,
  double x,
  double y,
  double size, {
  double width = 1000,
  Color color = AppColors.ink,
  String font = AppFonts.numerals,
  FontWeight weight = FontWeight.w800,
  double height = 1.04,
  TextAlign align = TextAlign.left,
}) {
  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: font,
            fontSize: size,
            fontWeight: weight,
            height: height,
            textAlign: align,
          ),
        )
        ..pushStyle(ui.TextStyle(color: color))
        ..addText(text);
  final paragraph = builder.build()
    ..layout(ui.ParagraphConstraints(width: width));
  c.drawParagraph(paragraph, Offset(x, y));
}

void line(
  Canvas c,
  List<Offset> points,
  Color color,
  double width, {
  bool close = false,
}) {
  final p = Path()..moveTo(points.first.dx, points.first.dy);
  for (final pt in points.skip(1)) {
    p.lineTo(pt.dx, pt.dy);
  }
  if (close) p.close();
  c.drawPath(
    p,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

// The exact mark coordinates shared with tool/splash/mark.swift and Android.
void mark(Canvas c, Rect rect, {bool monochrome = false}) {
  c.save();
  c.translate(rect.left, rect.top);
  c.scale(rect.width / 1024);
  if (!monochrome) {
    line(
      c,
      [const Offset(195, 184), const Offset(830, 164)],
      AppColors.highlighter,
      92,
    );
    line(
      c,
      [const Offset(205, 860), const Offset(820, 840)],
      AppColors.highlighter,
      92,
    );
    line(
      c,
      [const Offset(249, 163), const Offset(824, 163), const Offset(534, 665)],
      AppColors.ink.withValues(alpha: 0.55),
      18,
      close: true,
    );
    line(
      c,
      [
        const Offset(594, 440),
        const Offset(534, 335),
        const Offset(249, 840),
        const Offset(824, 840),
        const Offset(664, 568),
      ],
      AppColors.ink.withValues(alpha: 0.55),
      18,
    );
  }
  line(
    c,
    [const Offset(225, 173), const Offset(800, 173), const Offset(510, 675)],
    AppColors.ink,
    26,
    close: true,
  );
  line(
    c,
    [
      const Offset(570, 450),
      const Offset(510, 345),
      const Offset(225, 850),
      const Offset(800, 850),
      const Offset(640, 578),
    ],
    AppColors.ink,
    26,
  );
  c.restore();
}

void paper(Canvas c, Size size, Color color) {
  c.drawRect(Offset.zero & size, Paint()..color = color);
  final p = Paint()..color = AppColors.ink.withValues(alpha: 0.055);
  for (double x = 25; x < size.width; x += 28) {
    for (double y = 25; y < size.height; y += 28) {
      c.drawCircle(Offset(x, y), 1.0, p);
    }
  }
}

void brand(Canvas c, double x, double y, {double size = 27}) {
  mark(c, Rect.fromLTWH(x - 6, y - 12, size * 1.6, size * 1.6));
  textAt(c, 'Soon & Since', x + size * 1.7, y, size, width: 650);
}

Future<void> writeImage(ui.Image image, String path) async {
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final f = File('$output/$path');
  await f.create(recursive: true);
  await f.writeAsBytes(bytes!.buffer.asUint8List());
}

Future<void> canvasImage(
  int w,
  int h,
  String path,
  void Function(Canvas, Size) draw,
) async {
  final r = ui.PictureRecorder();
  final c = Canvas(r);
  draw(c, Size(w.toDouble(), h.toDouble()));
  final picture = r.endRecording();
  final image = await picture.toImage(w, h);
  await writeImage(image, path);
  image.dispose();
  picture.dispose();
}

void framed(Canvas c, ui.Image shot, Rect box, {double radius = 38}) {
  final frame = RRect.fromRectAndRadius(box, const Radius.circular(38));
  c.drawRRect(
    frame.shift(const Offset(9, 14)),
    Paint()..color = AppColors.ink.withValues(alpha: 0.12),
  );
  c.drawRRect(frame, Paint()..color = AppColors.ink);
  final inside = RRect.fromRectAndRadius(
    box.deflate(9),
    Radius.circular(radius - 8),
  );
  c.save();
  c.clipRRect(inside);
  c.drawImageRect(
    shot,
    Rect.fromLTWH(0, 0, shot.width.toDouble(), shot.height.toDouble()),
    inside.outerRect,
    Paint()..filterQuality = FilterQuality.high,
  );
  c.restore();
}

Future<void> campaign(ui.Image shot, Device device, int index) async {
  final w = (device.size.width * device.scale).round(),
      h = (device.size.height * device.scale).round();
  final tablet = device.size.width > device.size.height;
  await canvasImage(w, h, 'campaign/${device.path}/${slugs[index]}.png', (
    canvas,
    size,
  ) {
    canvas.scale(size.width / 1000);
    final height = size.height * 1000 / size.width;
    paper(canvas, Size(1000, height), grounds[index]);
    if (tablet && device.platform == TargetPlatform.android) {
      brand(canvas, 48, 25, size: 18);
      final title = index == 5
          ? 'Give your days a bigger picture.'
          : headlines[index].replaceAll('\n', ' ');
      textAt(canvas, title, 48, 63, 46, width: 910, height: 1.0);
      textAt(
        canvas,
        index == 5
            ? 'Turn your tablet into a beautiful countdown board.'
            : subtitles[index],
        50,
        120,
        18,
        width: 910,
        font: AppFonts.ui,
        weight: FontWeight.w500,
      );
      final available = height - 184;
      final sw = (available * shot.width / shot.height)
          .clamp(0, 900)
          .toDouble();
      framed(
        canvas,
        shot,
        Rect.fromLTWH((1000 - sw) / 2, 164, sw, available),
        radius: 24,
      );
    } else if (tablet) {
      brand(canvas, 48, 35, size: 20);
      final title = index == 5
          ? 'Give your days\na bigger picture.'
          : headlines[index];
      textAt(canvas, title, 48, 95, 64, width: 900, height: 1.0);
      textAt(
        canvas,
        index == 5
            ? 'Turn your tablet into a beautiful countdown board.'
            : subtitles[index],
        50,
        237,
        20,
        width: 870,
        font: AppFonts.ui,
        weight: FontWeight.w500,
      );
      final available = height - 310;
      final sw = (available * shot.width / shot.height)
          .clamp(0, 900)
          .toDouble();
      framed(
        canvas,
        shot,
        Rect.fromLTWH((1000 - sw) / 2, 294, sw, available - 10),
        radius: 24,
      );
    } else {
      brand(canvas, 58, 55, size: 26);
      textAt(canvas, headlines[index], 58, 145, 99, width: 890, height: 1.01);
      line(
        canvas,
        [const Offset(61, 355), const Offset(453, 347)],
        AppColors.highlighter,
        17,
      );
      textAt(
        canvas,
        subtitles[index],
        61,
        387,
        28,
        width: 870,
        font: AppFonts.ui,
        weight: FontWeight.w500,
        height: 1.3,
      );
      final available = height - 540;
      final sw = (available * shot.width / shot.height)
          .clamp(0, 850)
          .toDouble();
      framed(canvas, shot, Rect.fromLTWH((1000 - sw) / 2, 510, sw, available));
    }
  });
}

void artwork(Canvas c, Rect safe) {
  // All meaningful artwork stays in Apple's published safe area. Background
  // paper and tiny decorative marks may be cropped by the store.
  final side = safe.height * 0.91;
  mark(
    c,
    Rect.fromLTWH(
      safe.center.dx - side / 2,
      safe.center.dy - side / 2,
      side,
      side,
    ),
  );
  for (final (x, y, r) in [
    (-0.33, -0.27, 0.045),
    (0.31, 0.24, 0.035),
    (-0.27, 0.25, 0.027),
  ]) {
    final p = Offset(
      safe.center.dx + x * safe.width,
      safe.center.dy + y * safe.height,
    );
    final rr = r * safe.height;
    line(
      c,
      [p - Offset(rr, 0), p + Offset(rr, 0)],
      AppColors.ink.withValues(alpha: 0.6),
      safe.height * 0.006,
    );
    line(
      c,
      [p - Offset(0, rr), p + Offset(0, rr)],
      AppColors.ink.withValues(alpha: 0.6),
      safe.height * 0.006,
    );
  }
}

Future<void> exports() async {
  for (final spec in [
    (3840, 1646, 'header.png', const Rect.fromLTWH(1097, 493, 1646, 661)),
    (
      3840,
      2560,
      'search-results.png',
      const Rect.fromLTWH(836, 765, 2168, 1030),
    ),
    (5244, 2950, 'universal.png', const Rect.fromLTWH(1921, 660, 1402, 962)),
  ]) {
    await canvasImage(
      spec.$1,
      spec.$2,
      'campaign/apple/header-and-search-results/${spec.$3}',
      (c, s) {
        paper(c, s, AppColors.paper);
        artwork(c, spec.$4);
      },
    );
    await canvasImage(spec.$1, spec.$2, 'review/apple-safe-areas/${spec.$3}', (
      c,
      s,
    ) {
      paper(c, s, AppColors.paper);
      artwork(c, spec.$4);
      c.drawRect(
        spec.$4,
        Paint()
          ..color = const Color(0xFF269A68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      );
    });
  }
  await canvasImage(1024, 500, 'campaign/google-play/feature-graphic.png', (
    c,
    s,
  ) {
    paper(c, s, AppColors.highlighter);
    brand(c, 58, 46, size: 29);
    textAt(c, 'Every day\nhas a story.', 58, 132, 76, width: 650);
    textAt(
      c,
      'Count down. Count up. Make it yours.',
      61,
      330,
      23,
      width: 615,
      font: AppFonts.ui,
      weight: FontWeight.w600,
    );
    mark(c, const Rect.fromLTWH(704, 142, 260, 260));
  });
  for (final size in [512, 1024]) {
    await canvasImage(size, size, 'brand/icon-$size.png', (c, s) {
      c.drawRect(Offset.zero & s, Paint()..color = Colors.white);
      mark(c, Offset.zero & s);
    });
  }
  await canvasImage(1600, 1000, 'brand/brand-board.png', (c, s) {
    paper(c, s, AppColors.paper);
    brand(c, 80, 70, size: 43);
    textAt(
      c,
      'For the days ahead.\nAnd the days behind.',
      80,
      185,
      86,
      width: 1380,
    );
    textAt(
      c,
      'Bricolage Grotesque + Inter',
      85,
      430,
      29,
      font: AppFonts.ui,
      weight: FontWeight.w500,
    );
    final colors = [
      AppColors.paper,
      AppColors.ink,
      AppColors.highlighter,
      const Color(0xFFE0F2E9),
      const Color(0xFFF4E7F5),
      const Color(0xFFDDEEF5),
    ];
    final names = [
      'Paper / FBF9F3',
      'Ink / 2E2A3A',
      'Highlighter / FFE36E',
      'Mint / E0F2E9',
      'Lilac / F4E7F5',
      'Sky / DDEEF5',
    ];
    for (var i = 0; i < colors.length; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(80 + i * 245, 560, 220, 205),
          const Radius.circular(24),
        ),
        Paint()..color = colors[i],
      );
      textAt(
        c,
        names[i],
        82 + i * 245,
        790,
        20,
        width: 230,
        font: AppFonts.ui,
        weight: FontWeight.w600,
      );
    }
    textAt(
      c,
      'Soon & Since  /  Store identity  /  3.0',
      84,
      911,
      21,
      font: AppFonts.ui,
      weight: FontWeight.w500,
    );
  });
}

Future<ui.Image> readImage(String path) async {
  final codec = await ui.instantiateImageCodec(
    await File('$output/$path').readAsBytes(),
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}

void imageIn(Canvas c, ui.Image image, Rect rect) {
  final scale = (rect.width / image.width).clamp(
    0.0,
    rect.height / image.height,
  );
  final w = image.width * scale, h = image.height * scale;
  c.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromCenter(center: rect.center, width: w, height: h),
    Paint()..filterQuality = FilterQuality.high,
  );
}

Future<void> review() async {
  final phone = <ui.Image>[], tablets = <ui.Image>[];
  for (final slug in slugs.take(6)) {
    phone.add(await readImage('campaign/apple/iphone/$slug.png'));
  }
  for (final path in [
    'apple/ipad-13',
    'google-play/tablet-7',
    'google-play/tablet-10',
  ]) {
    tablets.add(await readImage('campaign/$path/01-soon.png'));
  }
  final feature = await readImage('campaign/google-play/feature-graphic.png');
  final header = await readImage(
    'campaign/apple/header-and-search-results/header.png',
  );
  await canvasImage(2000, 1850, 'review/overview.png', (c, s) {
    paper(c, s, AppColors.paper);
    brand(c, 50, 36, size: 36);
    textAt(
      c,
      'Store artwork  /  3.0',
      1450,
      43,
      26,
      width: 500,
      font: AppFonts.ui,
      weight: FontWeight.w500,
    );
    for (var i = 0; i < phone.length; i++) {
      imageIn(c, phone[i], Rect.fromLTWH(50 + i * 320, 130, 300, 670));
    }
    final names = [
      'iPad 13-inch',
      'Android tablet 7-inch',
      'Android tablet 10-inch',
    ];
    for (var i = 0; i < tablets.length; i++) {
      textAt(c, names[i], 50 + i * 650, 845, 25, width: 600);
      imageIn(c, tablets[i], Rect.fromLTWH(50 + i * 650, 900, 600, 470));
    }
    textAt(c, 'Google Play feature graphic', 50, 1410, 25);
    imageIn(c, feature, const Rect.fromLTWH(50, 1460, 740, 360));
    textAt(c, 'Apple product page header', 850, 1410, 25);
    imageIn(c, header, const Rect.fromLTWH(850, 1460, 1100, 360));
  });
  for (final device in devices) {
    final images = <ui.Image>[];
    for (final slug in slugs) {
      images.add(await readImage('campaign/${device.path}/$slug.png'));
    }
    final tablet = device.size.width > device.size.height;
    final cellHeight = tablet ? 335.0 : 960.0;
    await canvasImage(
      1800,
      (cellHeight * 2 + 150).round(),
      'review/contact-sheets/${device.path.replaceAll('/', '-')}.png',
      (c, s) {
        paper(c, s, AppColors.paper);
        textAt(c, device.path, 30, 24, 30);
        for (var i = 0; i < images.length; i++) {
          imageIn(
            c,
            images[i],
            Rect.fromLTWH(
              15 + (i % 4) * 450,
              90 + (i ~/ 4) * cellHeight,
              425,
              cellHeight - 25,
            ),
          );
        }
      },
    );
    for (final image in images) {
      image.dispose();
    }
  }
  await canvasImage(1800, 580, 'review/android-launcher.png', (c, s) {
    paper(c, s, AppColors.paper);
    textAt(c, 'One mark. Every launcher.', 55, 38, 46);
    final names = [
      'Play Store',
      'Legacy launcher',
      'Adaptive / circle',
      'Adaptive / squircle',
      'Themed icon',
    ];
    for (var i = 0; i < names.length; i++) {
      final box = Rect.fromLTWH(65 + i * 350, 180, 260, 260);
      c.save();
      if (i == 2 || i == 4) {
        c.clipPath(Path()..addOval(box));
      } else if (i == 3) {
        c.clipRRect(RRect.fromRectAndRadius(box, const Radius.circular(60)));
      }
      c.drawRect(
        box,
        Paint()..color = i == 4 ? const Color(0xFFDDDAED) : Colors.white,
      );
      if (i < 2) {
        mark(c, box);
      } else {
        mark(
          c,
          Rect.fromCenter(
            center: box.center,
            width: box.width * 0.62,
            height: box.height * 0.62,
          ),
          monochrome: i == 4,
        );
      }
      c.restore();
      textAt(
        c,
        names[i],
        40 + i * 350,
        478,
        23,
        width: 310,
        align: TextAlign.center,
        font: AppFonts.ui,
        weight: FontWeight.w600,
      );
    }
  });
  for (final image in [...phone, ...tablets, feature, header]) {
    image.dispose();
  }
}

void main() {
  testWidgets('export real app screens and store campaign', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() {
      WidgetController.hitTestWarningShouldBeFatal = false;
      debugDefaultTargetPlatformOverride = null;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(loadFonts);
    PhotoStore.setUp(Directory('tool/store-assets').absolute);
    await tester.runAsync(warmPhoto);
    // This export harness runs through flutter_test, outside the CI test folder.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'localSettings': jsonEncode({
        'hapticFeedback': false,
        'soundEffects': false,
        'notify': true,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    for (final device in devices) {
      debugDefaultTargetPlatformOverride = device.platform;
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = device.size;
      final tablet = device.size.width > device.size.height;
      for (var i = 0; i < slugs.length; i++) {
        final container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            eventsProvider.overrideWithValue(examples),
            clockProvider.overrideWith(_Clock.new),
            minuteClockProvider.overrideWith(_Minute.new),
          ],
        );
        if (i == 1) {
          container.read(homeFilterProvider.notifier).set(HomeFilter.since);
        }
        final Widget screen = switch (i) {
          0 || 1 => const HomeScreen(),
          2 => const EventScreen(eventKey: '1'),
          3 || 4 || 6 => const EditorScreen(eventKey: '2'),
          _ =>
            tablet
                ? const WallScreen()
                : Scaffold(
                    body: SafeArea(
                      child: ShareSheet(
                        event: examples[2],
                        unit: CountUnit.days,
                      ),
                    ),
                  ),
        };
        final key = GlobalKey();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: RepaintBoundary(
              key: key,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(),
                home: screen,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: EdgeInsets.only(
                      top: tablet ? 24 : 44,
                      bottom: tablet ? 20 : 24,
                    ),
                    viewPadding: EdgeInsets.only(
                      top: tablet ? 24 : 44,
                      bottom: tablet ? 20 : 24,
                    ),
                  ),
                  child: child!,
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
        // Let local photo files finish decoding, including resized card caches.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        if ((i == 3 || i == 6) && !tablet) {
          await tester.tap(find.text('Look'));
          await tester.pump(const Duration(milliseconds: 300));
        }
        if (i == 6) {
          await tester.tap(find.text('All backgrounds'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Patterns'));
          await tester.tap(find.text('Patterns'));
          await tester.pumpAndSettle();
        }
        if (i == 4) {
          final target = find.text('Remind me');
          if (target.evaluate().isNotEmpty) {
            await tester.ensureVisible(target);
            await tester.pump(const Duration(milliseconds: 300));
          }
        }
        expect(
          tester.takeException(),
          isNull,
          reason: '${device.path}/${slugs[i]}',
        );
        if (i == 0 || i == 2 || (i == 5 && tablet)) {
          final photos = tester.widgetList<RawImage>(find.byType(RawImage));
          expect(photos, isNotEmpty);
          expect(
            photos.every((image) => image.image != null),
            isTrue,
            reason: 'Photo must be decoded before ${device.path}/${slugs[i]}',
          );
        }
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final shot = await boundary.toImage(pixelRatio: device.scale);
          await writeImage(shot, 'screenshots/${device.path}/${slugs[i]}.png');
          await campaign(shot, device, i);
          shot.dispose();
        });
        await tester.pumpWidget(const SizedBox.shrink());
        container.dispose();
        await tester.pump();
      }
    }
    await tester.runAsync(exports);
    await tester.runAsync(review);
  }, timeout: const Timeout(Duration(minutes: 8)));
}
