import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/rendering.dart';
import 'package:where_ma_money_go/models/saving.dart';

class SavingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _savings {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(uid).collection('savings');
  }

  // ✅ Cambiado de Future<dynamic> a Future<List<Saving>>
  Future<List<Saving>> getSavings() async {
    try {
      final snapshot = await _savings
          .orderBy('dueDate', descending: true)
          .get();
      debugPrint('Savings fetched: ${snapshot.docs.length}');
      return snapshot.docs
          .map((doc) => Saving.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener ahorros');
    }
  }

  Future<void> addSaving(Saving saving) async {
    try {
      await _savings.add(saving.toMap());
    } catch (e) {
      throw Exception('Error al agregar ahorro');
    }
  }

  Future<void> updateSaving(Saving saving) async {
    try {
      await _savings.doc(saving.id).update(saving.toMap());
    } catch (e) {
      throw Exception('Error al actualizar ahorro');
    }
  }

  Future<void> deleteSaving(String savingId) async {
    try {
      await _savings.doc(savingId).delete();
    } catch (e) {
      throw Exception('Error al eliminar ahorro');
    }
  }
}
