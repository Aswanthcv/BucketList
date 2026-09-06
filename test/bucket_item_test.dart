import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:bucketlist/features/bucket_list/models/bucket_item.dart';
import 'package:bucketlist/features/bucket_list/repositories/bucket_list_repository.dart';

void main() {
  late BucketListRepository repository;
  late Directory testDir;

  setUp(() async {
    testDir = Directory.systemTemp.createTempSync();
    Hive.init(testDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(BucketItemAdapter());
    }

    repository = BucketListRepository();
    await repository.init();
  });

  tearDown(() async {
    await Hive.close();
    testDir.deleteSync(recursive: true);
  });

  test('Add and retrieve BucketItem', () {
    final item = BucketItem(
      id: '1',
      title: 'Visit Paris',
      category: 'Travel',
      estimatedPrice: 2000.0,
      note: 'During summer',
      createdAt: DateTime(2024, 1, 1),
    );

    repository.add(item);
    final items = repository.getAll();

    expect(items.length, 1);
    expect(items.first.title, 'Visit Paris');
    expect(items.first.estimatedPrice, 2000.0);
    expect(items.first.isCompleted, false);
  });

  test('Update BucketItem', () {
    final item = BucketItem(
      id: '1',
      title: 'Visit Paris',
      category: 'Travel',
      estimatedPrice: 2000.0,
      createdAt: DateTime(2024, 1, 1),
    );

    repository.add(item);

    final updatedItem = item.copyWith(
      title: 'Visit Paris 2025',
      estimatedPrice: 2500.0,
    );
    repository.update(updatedItem);

    final items = repository.getAll();
    expect(items.first.title, 'Visit Paris 2025');
    expect(items.first.estimatedPrice, 2500.0);
  });

  test('Delete BucketItem', () {
    final item = BucketItem(
      id: '1',
      title: 'Visit Paris',
      category: 'Travel',
      estimatedPrice: 2000.0,
      createdAt: DateTime(2024, 1, 1),
    );

    repository.add(item);
    expect(repository.count, 1);

    repository.delete('1');
    expect(repository.count, 0);
  });

  test('BucketItem copyWith works correctly', () {
    final item = BucketItem(
      id: '1',
      title: 'Original Title',
      category: 'Travel',
      estimatedPrice: 1000.0,
      note: 'Original note',
      createdAt: DateTime(2024, 1, 1),
      isCompleted: false,
    );

    final copy = item.copyWith(
      title: 'New Title',
      isCompleted: true,
    );

    expect(copy.id, '1');
    expect(copy.title, 'New Title');
    expect(copy.category, 'Travel');
    expect(copy.estimatedPrice, 1000.0);
    expect(copy.note, 'Original note');
    expect(copy.isCompleted, true);
  });

  test('End-to-end: create, save, read, update, read, delete, confirm', () async {
    final created = BucketItem(
      id: 'abc-123',
      title: 'Learn to paint',
      category: 'Skills',
      estimatedPrice: 50.0,
      note: 'Watercolors',
      createdAt: DateTime(2024, 5, 10),
    );

    repository.add(created);
    var items = repository.getAll();
    expect(items.any((i) => i.id == 'abc-123'), true);

    final updated = created.copyWith(
      title: 'Learn to paint portraits',
      note: 'Acrylics',
    );
    repository.update(updated);

    items = repository.getAll();
    final reloaded = items.firstWhere((i) => i.id == 'abc-123');
    expect(reloaded.title, 'Learn to paint portraits');
    expect(reloaded.note, 'Acrylics');
    expect(reloaded.estimatedPrice, 50.0);

    repository.delete('abc-123');
    items = repository.getAll();
    expect(items.any((i) => i.id == 'abc-123'), false);
  });

  test('actualPrice defaults to null', () {
    final item = BucketItem(
      id: '1',
      title: 'Visit Paris',
      category: 'Travel',
      estimatedPrice: 2000.0,
      createdAt: DateTime(2024, 1, 1),
    );
    expect(item.actualPrice, isNull);
  });

  test('actualPrice persists through save and read', () {
    final item = BucketItem(
      id: '1',
      title: 'Buy headphones',
      category: 'Gadgets',
      estimatedPrice: 3000.0,
      actualPrice: 2750.0,
      createdAt: DateTime(2024, 1, 1),
      isCompleted: true,
    );

    repository.add(item);

    final loaded = repository.getAll().single;
    expect(loaded.actualPrice, 2750.0);
  });

  test('copyWith can set and clear actualPrice', () {
    final item = BucketItem(
      id: '1',
      title: 'Buy headphones',
      category: 'Gadgets',
      estimatedPrice: 3000.0,
      createdAt: DateTime(2024, 1, 1),
    );

    final withActual = item.copyWith(actualPrice: 2750.0);
    expect(withActual.actualPrice, 2750.0);

    final withActualSet = withActual.copyWith(actualPrice: 2800.0);
    expect(withActualSet.actualPrice, 2800.0);

    final cleared = withActualSet.copyWith(actualPrice: null);
    expect(cleared.actualPrice, isNull);
  });

  test('copyWith keeps actualPrice when not provided', () {
    final item = BucketItem(
      id: '1',
      title: 'Buy headphones',
      category: 'Gadgets',
      estimatedPrice: 3000.0,
      actualPrice: 2700.0,
      createdAt: DateTime(2024, 1, 1),
    );

    final copy = item.copyWith(title: 'New title');
    expect(copy.actualPrice, 2700.0);
  });

  test('Existing item without actualPrice reloads as null', () async {
    final item = BucketItem(
      id: 'legacy-1',
      title: 'Visit Goa',
      category: 'Travel',
      estimatedPrice: 15000.0,
      note: 'Trip',
      createdAt: DateTime(2024, 1, 1),
    );

    repository.add(item);

    // A fresh repository reading the same Hive box (legacy row without
    // actualPrice) must load the item with actualPrice == null.
    final reader = BucketListRepository();
    await reader.init();

    final loaded = reader.getAll().single;
    expect(loaded.id, 'legacy-1');
    expect(loaded.estimatedPrice, 15000.0);
    expect(loaded.actualPrice, isNull);
  });

  test('isFavorite defaults to false', () {
    final item = BucketItem(
      id: '1',
      title: 'Visit Paris',
      category: 'Travel',
      estimatedPrice: 2000.0,
      createdAt: DateTime(2024, 1, 1),
    );
    expect(item.isFavorite, false);
  });

  test('isFavorite persists through save and read', () async {
    final item = BucketItem(
      id: '7',
      title: 'Buy headphones',
      category: 'Gadgets',
      estimatedPrice: 3000.0,
      createdAt: DateTime(2024, 1, 1),
      isFavorite: true,
    );

    repository.add(item);

    final loaded = repository.getAll().single;
    expect(loaded.isFavorite, true);
  });

  test('Non-favorite reloads as false through a fresh repository', () async {
    final item = BucketItem(
      id: 'legacy-2',
      title: 'Visit Goa',
      category: 'Travel',
      estimatedPrice: 15000.0,
      createdAt: DateTime(2024, 1, 1),
      isFavorite: false,
    );

    repository.add(item);

    final reader = BucketListRepository();
    await reader.init();

    final loaded = reader.getAll().single;
    expect(loaded.isFavorite, false);
  });

  test('copyWith can set and clear isFavorite', () {
    final item = BucketItem(
      id: '1',
      title: 'Buy headphones',
      category: 'Gadgets',
      estimatedPrice: 3000.0,
      createdAt: DateTime(2024, 1, 1),
    );

    expect(item.copyWith(isFavorite: true).isFavorite, true);
    expect(item.copyWith(isFavorite: false).isFavorite, false);
  });

  test('copyWith keeps isFavorite when not provided', () {
    final item = BucketItem(
      id: '1',
      title: 'Buy headphones',
      category: 'Gadgets',
      estimatedPrice: 3000.0,
      createdAt: DateTime(2024, 1, 1),
      isFavorite: true,
    );

    final copy = item.copyWith(title: 'New title');
    expect(copy.isFavorite, true);
  });
}
