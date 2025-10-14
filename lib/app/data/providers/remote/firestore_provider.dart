import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference collection(String path) => _firestore.collection(path);

  Future<DocumentSnapshot> getDoc(String path, String id) => collection(path).doc(id).get();
  Future<void> setDoc(String path, String id, Map<String, dynamic> data) => collection(path).doc(id).set(data);
}
