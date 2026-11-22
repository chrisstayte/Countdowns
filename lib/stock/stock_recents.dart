import 'dart:convert';

import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:countdowns/stock/stock_photo_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _key = 'recentStockPhotos';

/// How many recently used stock photos are remembered.
const stockRecentsLimit = 15;

/// Stock photos the person picked before, newest first, with their
/// metadata so the row works offline and after they leave the catalogue.
final stockRecentsProvider =
    NotifierProvider<StockRecentsController, List<StockPhoto>>(
      StockRecentsController.new,
    );

class StockRecentsController extends Notifier<List<StockPhoto>> {
  @override
  List<StockPhoto> build() {
    final raw = ref.watch(preferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          if (j is Map) ?StockPhoto.fromJson(j.cast<String, Object?>()),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> use(StockPhoto photo) async {
    state = pushRecent(state, photo);
    await ref
        .read(preferencesProvider)
        .setString(_key, jsonEncode([for (final p in state) p.toJson()]));
  }
}

/// [photo] first, no duplicates by id, at most [stockRecentsLimit].
List<StockPhoto> pushRecent(List<StockPhoto> list, StockPhoto photo) => [
  photo,
  ...list.where((p) => p.id != photo.id),
].take(stockRecentsLimit).toList();
