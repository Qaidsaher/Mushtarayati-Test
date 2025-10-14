import 'package:get_storage/get_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final GetStorage _box = GetStorage();

  T? read<T>(String key) => _box.read(key) as T?;
  Future<void> write(String key, dynamic value) async => _box.write(key, value);
  Future<void> remove(String key) async => _box.remove(key);
}
