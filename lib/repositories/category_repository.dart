import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:where_ma_money_go/models/category.dart';

class CategoryRepository {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String uid = FirebaseAuth.instance.currentUser!.uid;

  Future<List<Categories>> getCategories() async {
    try {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .get();
      return snapshot.docs.map((doc) => Categories.fromMap(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<void> addCategory(Categories category) async {
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .add(category.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(Categories category) async {
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(category.id)
          .update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await firestore
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(categoryId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
