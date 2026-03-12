import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:where_ma_money_go/models/envelop.dart';

class EnvelopRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _envelops {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(uid).collection('envelops');
  }

  Future<List<Envelop>> getEnvelops() async {
    final snapshot = await _envelops
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs
        .map((doc) => Envelop.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> createEnvelop(Envelop envelop) async {
    await _envelops.add({
      ...envelop.toMap(),
      'createdAt': envelop.createdAt.toIso8601String(),
    });
  }

  Future<void> updateEnvelop(Envelop envelop) async {
    await _envelops.doc(envelop.id).update(envelop.toMap());
  }

  Future<void> deleteEnvelop(String envelopId) async {
    await _envelops.doc(envelopId).delete();
  }
}
