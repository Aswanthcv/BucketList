import 'package:hive/hive.dart';

class BucketItem extends HiveObject {
  static const Object _unset = Object();

  final String id;
  final String title;
  final String category;
  final double estimatedPrice;
  final String? note;
  final DateTime createdAt;
  bool isCompleted;
  double? actualPrice;
  bool isFavorite;

  BucketItem({
    required this.id,
    required this.title,
    required this.category,
    required this.estimatedPrice,
    this.note,
    required this.createdAt,
    this.isCompleted = false,
    this.actualPrice,
    this.isFavorite = false,
  });

  BucketItem copyWith({
    String? title,
    String? category,
    double? estimatedPrice,
    String? note,
    bool? isCompleted,
    Object? actualPrice = _unset,
    bool? isFavorite,
  }) {
    return BucketItem(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      note: note ?? this.note,
      createdAt: createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
      actualPrice: identical(actualPrice, _unset)
          ? this.actualPrice
          : actualPrice as double?,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class BucketItemAdapter extends TypeAdapter<BucketItem> {
  @override
  final int typeId = 0;

  @override
  BucketItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return BucketItem(
      id: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      estimatedPrice: fields[3] as double,
      note: fields[4] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[5] as int),
      isCompleted: fields[6] as bool,
      actualPrice: fields[7] as double?,
      isFavorite: fields[8] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, BucketItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.estimatedPrice)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.isCompleted)
      ..writeByte(7)
      ..write(obj.actualPrice)
      ..writeByte(8)
      ..write(obj.isFavorite);
  }
}
