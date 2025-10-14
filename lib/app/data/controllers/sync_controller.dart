import 'dart:async';
import 'package:get/get.dart';
import '../services/sync_service.dart';

class SyncController extends GetxController {
  final _service = SyncService();
  final status = 'idle'.obs;
  final lastSyncAt = RxnInt();
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    // auto-sync every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => autoSync());
  }

  Future<void> autoSync() async {
    status.value = 'syncing';
    try {
      await _service.syncOnce();
      lastSyncAt.value = DateTime.now().millisecondsSinceEpoch;
      status.value = 'idle';
    } catch (e) {
      status.value = 'error';
    }
  }

  Future<void> syncNow() async {
    status.value = 'syncing';
    try {
      await _service.syncOnce();
      lastSyncAt.value = DateTime.now().millisecondsSinceEpoch;
      status.value = 'idle';
    } catch (e) {
      status.value = 'error';
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
