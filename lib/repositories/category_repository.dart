import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:where_ma_money_go/models/category.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _categories {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(uid).collection('categories');
  }

  Future<List<Categories>> getCategories() async {
    try {
      final snapshot = await _categories.orderBy('name').get();
      return snapshot.docs.map((doc) => Categories.fromMap(doc)).toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<void> addCategory(Categories category) async {
    try {
      await _categories.add(category.toMap());
    } catch (e) {
      throw Exception('Failed to add category: $e');
    }
  }

  Future<void> updateCategory(Categories category) async {
    try {
      await _categories.doc(category.id).update(category.toMap());
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categories.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}
