import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:countdowns/fonts/font_catalog.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Google Fonts on the device, downloaded one file per family and only when
/// someone uses them. Nothing here needs a key or a server of our own: the
/// files come straight from fonts.gstatic.com and are checked against the
/// SHA-256 in the bundled catalogue.
///
/// Two folders:
/// - **installed**: fonts countdowns use, in the widgets' folder (the App
///   Group on iOS, files on Android) so the widgets draw titles from the
///   same file the app does. See WidgetSnapshotWriter.
/// - **cache**: fonts only previewed in the picker. The system may clear it.
///
/// Fonts load into Flutter as `gf:<family>`. Text asks for that family with
/// the Default font as fallback (see eventFontFallback), so a title shows in
/// Default until its file is ready and then redraws by itself.
class FontLibrary {
  FontLibrary._();

  static final instance = FontLibrary._();

  /// The Flutter family a Google font loads as.
  static String flutterFamily(String family) => 'gf:$family';

  /// The file name a family is stored under, in either folder.
  static String fileName(String family) =>
      '${family.replaceAll(RegExp('[^A-Za-z0-9]+'), '_')}.ttf';

  /// Where widgets find an installed font, relative to their folder.
  static String widgetPath(String family) => 'fonts/${fileName(family)}';

  Directory? _installed;
  Directory? _cache;
  http.Client? _httpClient;
  http.Client get _client => _httpClient ??= http.Client();
  Future<FontCatalog> Function() _catalog = FontCatalog.load;

  /// Bumps whenever a font finishes loading or fails, for pickers that show
  /// a loading state.
  final revision = ValueNotifier<int>(0);

  /// Called after a font is newly installed, so the widgets can pick it up.
  VoidCallback? onInstalled;

  final _loaded = <String>{};
  final _loads = <String, Future<bool>>{};
  final _installs = <String, Future<bool>>{};
  final _downloads = <String, Future<File?>>{};
  final _failedAt = <String, DateTime>{};
  bool _offline = false;

  /// True while the last download failed for want of a connection.
  bool get offline => _offline;

  bool get ready => _installed != null;

  void setUp({
    required Directory installed,
    required Directory cache,
    http.Client? client,
    Future<FontCatalog> Function()? catalog,
  }) {
    _installed = installed;
    _cache = cache;
    if (client != null) _httpClient = client;
    if (catalog != null) _catalog = catalog;
  }

  /// Forgets everything; for tests.
  @visibleForTesting
  void reset() {
    _installed = null;
    _cache = null;
    _httpClient = null;
    _catalog = FontCatalog.load;
    onInstalled = null;
    _loaded.clear();
    _loads.clear();
    _installs.clear();
    _downloads.clear();
    _failedAt.clear();
    _queue.clear();
    _active = 0;
    _offline = false;
  }

  bool isLoaded(String family) => _loaded.contains(family);

  /// True if the last try failed recently; the picker shows it as offline.
  bool failed(String family) => _failedAt.containsKey(family);

  /// For a countdown's font: makes sure the file is installed where the
  /// widgets can read it, and loads it into Flutter. Cheap to call from
  /// build; repeats share one try, and a failed try waits a while before
  /// the next.
  Future<bool> use(String family) {
    if (!ready) return Future.value(false);
    final running = _installs[family];
    if (running != null) return running;
    if (_tooSoon(family)) return Future.value(false);
    final future = _install(family).then((ok) async {
      return ok && await _loadFrom(family, _installedFile(family));
    });
    _installs[family] = future;
    future.then((ok) {
      if (!ok) _installs.remove(family);
    });
    return future;
  }

  /// For the picker: loads a font from wherever it already is, downloading
  /// it into the cache if needed. Doesn't install it.
  Future<bool> preview(String family) {
    if (!ready) return Future.value(false);
    if (_loaded.contains(family)) return Future.value(true);
    final running = _loads[family] ?? _installs[family];
    if (running != null) return running;
    if (_tooSoon(family)) return Future.value(false);
    final future = () async {
      final installed = _installedFile(family);
      if (await installed.exists()) return _loadFrom(family, installed);
      final file = await _download(family);
      return file != null && await _loadFrom(family, file);
    }();
    _loads[family] = future;
    future.then((ok) {
      if (!ok) _loads.remove(family);
    });
    return future;
  }

  /// Drops a preview that hasn't started downloading yet, for rows that
  /// scrolled away.
  void cancelPreview(String family) {
    // A countdown wants it too: let it finish.
    if (_installs.containsKey(family)) return;
    final waiting = _queue.where((w) => w.family == family).toList();
    for (final w in waiting) {
      _queue.remove(w);
      w.go.complete(false);
    }
  }

  /// The installed file for widgets, or null if it isn't there.
  Future<File?> installedFile(String family) async {
    if (!ready) return null;
    final f = _installedFile(family);
    return await f.exists() ? f : null;
  }

  /// Moves installed fonts no countdown uses back to the cache, so the
  /// widgets' folder only holds what they need and a font picked again
  /// later doesn't download twice.
  Future<void> prune(Set<String> keep) async {
    final dir = _installed;
    final cache = _cache;
    if (dir == null || cache == null || !await dir.exists()) return;
    final keepFiles = {for (final f in keep) fileName(f)};
    await for (final f in dir.list()) {
      if (f is! File || keepFiles.contains(p.basename(f.path))) continue;
      try {
        await cache.create(recursive: true);
        await f.copy(p.join(cache.path, p.basename(f.path)));
        await f.delete();
      } catch (_) {}
    }
    _installs.removeWhere((family, _) => !keep.contains(family));
  }

  /// Keeps the preview cache under [maxBytes], dropping the oldest files.
  Future<void> trimCache({int maxBytes = 40 * 1024 * 1024}) async {
    final dir = _cache;
    if (dir == null || !await dir.exists()) return;
    final files = <(File, FileStat)>[];
    await for (final f in dir.list()) {
      if (f is File) files.add((f, await f.stat()));
    }
    var total = files.fold<int>(0, (sum, f) => sum + f.$2.size);
    if (total <= maxBytes) return;
    files.sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    for (final (file, stat) in files) {
      if (total <= maxBytes) break;
      try {
        await file.delete();
        total -= stat.size;
      } catch (_) {}
    }
  }

  // MARK: internals

  File _installedFile(String family) =>
      File(p.join(_installed!.path, fileName(family)));

  File _cachedFile(String family) =>
      File(p.join(_cache!.path, fileName(family)));

  bool _tooSoon(String family) {
    final at = _failedAt[family];
    return at != null &&
        DateTime.now().difference(at) < const Duration(seconds: 30);
  }

  Future<bool> _install(String family) async {
    final target = _installedFile(family);
    if (await target.exists()) return true;
    final file = await _download(family);
    if (file == null) return false;
    try {
      await target.parent.create(recursive: true);
      final tmp = File('${target.path}.tmp');
      await file.copy(tmp.path);
      await tmp.rename(target.path);
      if (file.path != target.path) unawaited(_quietDelete(file));
      onInstalled?.call();
      return true;
    } catch (error, stack) {
      _report(error, stack, 'installing $family');
      return false;
    }
  }

  /// The family's file in the cache, downloading it if needed.
  Future<File?> _download(String family) =>
      _downloads[family] ??= _fetch(family).whenComplete(() {
        // A block, not an arrow: remove() returns this very future, and
        // whenComplete would wait on it forever.
        _downloads.remove(family);
      });

  Future<File?> _fetch(String family) async {
    final cached = _cachedFile(family);
    if (await cached.exists()) return cached;
    final font = (await _catalog())[family];
    if (font == null) return _fail(family);
    if (!await _slot(family)) return null;
    try {
      final response = await _client
          .get(font.url)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return _fail(family);
      final bytes = response.bodyBytes;
      if (bytes.length != font.length ||
          sha256.convert(bytes).toString() != font.hash) {
        return _fail(family);
      }
      await cached.parent.create(recursive: true);
      final tmp = File('${cached.path}.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename(cached.path);
      _offline = false;
      _failedAt.remove(family);
      return cached;
    } on SocketException {
      _offline = true;
      return _fail(family);
    } on http.ClientException {
      _offline = true;
      return _fail(family);
    } on TimeoutException {
      _offline = true;
      return _fail(family);
    } catch (error, stack) {
      _report(error, stack, 'downloading $family');
      return _fail(family);
    } finally {
      _release();
    }
  }

  Future<bool> _loadFrom(String family, File file) async {
    if (_loaded.contains(family)) return true;
    try {
      final bytes = await file.readAsBytes();
      final loader = FontLoader(flutterFamily(family))
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
      _loaded.add(family);
      revision.value++;
      return true;
    } catch (error, stack) {
      // A damaged file: drop it so the next try downloads a fresh copy.
      unawaited(_quietDelete(file));
      _report(error, stack, 'loading $family');
      _fail(family);
      return false;
    }
  }

  File? _fail(String family) {
    _failedAt[family] = DateTime.now();
    revision.value++;
    return null;
  }

  Future<void> _quietDelete(File f) async {
    try {
      await f.delete();
    } catch (_) {}
  }

  void _report(Object error, StackTrace stack, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'font library',
        context: ErrorDescription(context),
      ),
    );
  }

  // Up to four downloads at once; the rest wait their turn in order.
  static const _maxActive = 4;
  int _active = 0;
  final _queue = Queue<_Waiting>();

  Future<bool> _slot(String family) {
    if (_active < _maxActive) {
      _active++;
      return Future.value(true);
    }
    final w = _Waiting(family);
    _queue.add(w);
    return w.go.future;
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeFirst().go.complete(true);
    } else {
      _active--;
    }
  }
}

class _Waiting {
  _Waiting(this.family);
  final String family;
  final go = Completer<bool>();
}
