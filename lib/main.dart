import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/app.dart';
import 'features/bucket_list/models/bucket_item.dart';
import 'features/bucket_list/repositories/bucket_list_repository.dart';
import 'features/bucket_list/providers/bucket_list_provider.dart';
import 'theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(BucketItemAdapter());

  final repository = BucketListRepository();
  await repository.init();

  final themeSettings = await ThemeSettings.open();

  runApp(
    ProviderScope(
      overrides: [
        bucketListRepositoryProvider.overrideWithValue(repository),
        themeSettingsProvider.overrideWithValue(themeSettings),
      ],
      child: const BucketListApp(),
    ),
  );
}