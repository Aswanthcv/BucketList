import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class TutorialSettings {
  static const _boxName = 'app_settings';
  static const _key = 'hasSeenTutorial';

  final Box<dynamic>? _box;
  final bool _hasSeenTutorial;

  TutorialSettings._(this._box, this._hasSeenTutorial);

  static Future<TutorialSettings> open() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    return TutorialSettings._(box, box.get(_key) == true);
  }

  /// Defaults to already-seen so tests and non-overridden providers don't
  /// unexpectedly show the tutorial.
  factory TutorialSettings.inMemory([bool hasSeen = true]) {
    return TutorialSettings._(null, hasSeen);
  }

  bool get hasSeenTutorial => _hasSeenTutorial;

  void markSeen() {
    _box?.put(_key, true);
  }
}

final tutorialSettingsProvider = Provider<TutorialSettings>((ref) {
  return TutorialSettings.inMemory();
});

final tutorialNotifierProvider =
    NotifierProvider<TutorialNotifier, bool>(TutorialNotifier.new);

class TutorialNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(tutorialSettingsProvider).hasSeenTutorial;
  }

  void complete() {
    ref.read(tutorialSettingsProvider).markSeen();
    state = true;
  }
}