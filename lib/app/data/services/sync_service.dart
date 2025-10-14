import 'dart:convert';
import 'package:get/get.dart';
import '../providers/local/sqlite_provider.dart';
import '../providers/remote/firestore_provider.dart';
import '../models/ops_model.dart';

class SyncService extends GetxService {
  final FirestoreProvider _fire = FirestoreProvider();

  Future<void> syncOnce() async {
    final ops = await SqliteProvider.getUnsyncedOps();
    for (final map in ops) {
      final op = OpsModel.fromMap(map);
      try {
        // map entity_type to collection
        final collection = op.entityType;
        // implement retry with exponential backoff
        int attempt = 0;
        const maxAttempts = 4;
        while (attempt < maxAttempts) {
          try {
            if (op.action == 'upsert') {
              // last-write-wins: check remote updated_at
              final remoteDoc = await _fire.getDoc(collection, op.entityId);
              int remoteUpdated = 0;
              if (remoteDoc.exists) {
                final data = remoteDoc.data() as Map<String, dynamic>?;
                if (data != null && data['updated_at'] != null) remoteUpdated = data['updated_at'] as int;
              }

              if (op.updatedAt >= remoteUpdated) {
                final payloadDynamic = op.payload != null ? jsonDecode(op.payload!) : {};
                final payload = Map<String, dynamic>.from(payloadDynamic as Map);
                await _fire.setDoc(collection, op.entityId, payload);
              } else {
                // remote is newer, skip applying local op
              }
            } else if (op.action == 'delete') {
              final remoteDoc = await _fire.getDoc(collection, op.entityId);
              if (remoteDoc.exists) {
                await _fire.collection(collection).doc(op.entityId).delete();
              }
            }
            await SqliteProvider.markOpSynced(op.id);
            break;
          } catch (e) {
            attempt++;
            if (attempt >= maxAttempts) {
              // failed after retries; leave op unsynced for next run
              break;
            }
            final delayMs = (1000 * (1 << attempt));
            await Future.delayed(Duration(milliseconds: delayMs));
          }
        }
      } catch (e) {
        // stop or continue depending on policy; here we continue
        // could implement retry/backoff logic
      }
    }
  }
}
