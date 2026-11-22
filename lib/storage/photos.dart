import 'dart:io';

import 'package:path/path.dart' as p;

/// Photos are copied into the app's documents folder; events store only the
/// path relative to it, so the folder can move (backups, reinstalls).
class PhotoStore {
  PhotoStore._(this.root);

  static PhotoStore? _instance;
  static PhotoStore get instance =>
      _instance ?? (throw StateError('PhotoStore not set up'));
  static bool get ready => _instance != null;

  static void setUp(Directory documents) =>
      _instance = PhotoStore._(documents.path);

  final String root;

  File fileFor(String relativePath) => File(p.join(root, relativePath));

  /// Copies [source] in and returns the relative path to store.
  Future<String> import(String source) async {
    final dir = Directory(p.join(root, 'photos'));
    await dir.create(recursive: true);
    final ext = p.extension(source).toLowerCase();
    final name =
        '${DateTime.now().microsecondsSinceEpoch}${ext.isEmpty ? '.jpg' : ext}';
    await File(source).copy(p.join(dir.path, name));
    return p.join('photos', name);
  }
}
