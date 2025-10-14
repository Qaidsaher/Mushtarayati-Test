import 'package:get_storage/get_storage.dart';

class ThemeService {
  static const _storageKey = 'isDarkMode';
  final GetStorage _storage = GetStorage();

  bool isDarkMode() {
    return _storage.read(_storageKey) ?? false;
  }

  void saveThemeMode(bool isDark) {
    _storage.write(_storageKey, isDark);
  }
}
