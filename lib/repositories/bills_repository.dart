import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:where_ma_money_go/models/bill.dart';

class BillsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _bills {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(uid).collection('bills');
  }

  Future<List<Bill>> getBills() async {
    final snapshot = await _bills.orderBy('date', descending: true).get();
    return snapshot.docs.map((doc) => Bill.fromMap(doc)).toList();
  }

  Future<void> addBill(Bill bill) async {
    await _bills.doc(bill.id).set(bill.toMap());
  }

  Future<void> updateBill(Bill bill) async {
    await _bills.doc(bill.id).update(bill.toMap());
  }

  Future<void> deleteBill(String id) async {
    await _bills.doc(id).delete();
  }
}
