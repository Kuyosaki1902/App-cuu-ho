class TrangDuLieu<T> {
  final List<T> items;
  final Object? cursor;
  final bool hasMore;
  const TrangDuLieu(this.items, this.cursor, this.hasMore);
}

Future<List<R>> taiTheoNhom<T, R>(
  Iterable<T> items,
  Future<R> Function(T) load, {
  int kichThuoc = 5,
}) async {
  if (kichThuoc < 1) throw ArgumentError.value(kichThuoc, 'kichThuoc');
  final result = <R>[];
  final batch = <Future<R>>[];
  for (final item in items) {
    batch.add(load(item));
    if (batch.length == kichThuoc) {
      result.addAll(await Future.wait(batch));
      batch.clear();
    }
  }
  if (batch.isNotEmpty) result.addAll(await Future.wait(batch));
  return result;
}
