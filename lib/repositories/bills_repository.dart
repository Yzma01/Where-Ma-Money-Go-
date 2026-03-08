import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:where_ma_money_go/models/bill.dart';

class BillsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> addBill(Bill billData) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .add(billData.toMap());
  }

  Future<void> updateBill(Bill billData) async {
    final billId = billData.id;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .doc(billId)
        .update(billData.toMap());
  }

  Future<void> deleteBill(String billId) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .doc(billId)
        .delete();
  }

  Future<List<Bill>> getBills() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('bills')
        .get();
    return snapshot.docs.map((doc) => Bill.fromMap(doc.data())).toList();
  }
}
