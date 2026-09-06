import 'package:hive/hive.dart';
import '../models/bucket_item.dart';

class BucketListRepository {
  static const String defaultBoxName = 'bucket_items';

  final String boxName;

  BucketListRepository({this.boxName = defaultBoxName});

  late Box<BucketItem> _box;

  Future<void> init() async {
    _box = await Hive.openBox<BucketItem>(boxName);
  }

  List<BucketItem> getAll() {
    return _box.values.toList();
  }

  void add(BucketItem item) {
    _box.put(item.id, item);
  }

  void update(BucketItem item) {
    _box.put(item.id, item);
  }

  void delete(String id) {
    _box.delete(id);
  }

  void clear() {
    _box.clear();
  }

  int get count => _box.length;
}