import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bucket_item.dart';
import '../repositories/bucket_list_repository.dart';

final bucketListRepositoryProvider = Provider<BucketListRepository>((ref) {
  throw UnimplementedError('Override during initialization');
});

final bucketListProvider =
    NotifierProvider<BucketListNotifier, List<BucketItem>>(
  BucketListNotifier.new,
);

class BucketListNotifier extends Notifier<List<BucketItem>> {
  BucketListRepository get _repo => ref.read(bucketListRepositoryProvider);

  @override
  List<BucketItem> build() {
    return _repo.getAll();
  }

  void addItem(BucketItem item) {
    _repo.add(item);
    state = _repo.getAll();
  }

  void updateItem(BucketItem item) {
    _repo.update(item);
    state = _repo.getAll();
  }

  void deleteItem(String id) {
    _repo.delete(id);
    state = _repo.getAll();
  }

  void toggleComplete(String id) {
    final items = _repo.getAll();
    final item = items.firstWhere((i) => i.id == id);
    item.isCompleted = !item.isCompleted;
    _repo.update(item);
    state = _repo.getAll();
  }

  void toggleFavorite(String id) {
    final items = _repo.getAll();
    final item = items.firstWhere((i) => i.id == id);
    item.isFavorite = !item.isFavorite;
    _repo.update(item);
    state = _repo.getAll();
  }

  void completeItem(String id, {double? actualPrice}) {
    final items = _repo.getAll();
    final item = items.firstWhere((i) => i.id == id);
    item.isCompleted = true;
    item.actualPrice = actualPrice;
    _repo.update(item);
    state = _repo.getAll();
  }

  void recordActualPrice(String id, double? actualPrice) {
    final items = _repo.getAll();
    final item = items.firstWhere((i) => i.id == id);
    item.actualPrice = actualPrice;
    _repo.update(item);
    state = _repo.getAll();
  }

  void clearAll() {
    _repo.clear();
    state = [];
  }
}
