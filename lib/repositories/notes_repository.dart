import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:where_ma_money_go/models/note.dart';

class NotesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notes {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Usuario no autenticado');
    return _firestore.collection('users').doc(uid).collection('notes');
  }

  Future<List<Note>> getNotes() async {
    try {
      final snapshot = await _notes.get();
      return snapshot.docs
          .map((doc) => Note.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener notas: $e');
    }
  }

  Future<void> addNote(Note note) async {
    try {
      await _notes.add(note.toMap());
    } catch (e) {
      throw Exception('Error al agregar nota: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await _notes.doc(id).delete();
    } catch (e) {
      throw Exception('Error al eliminar nota: $e');
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      await _notes.doc(note.id).update(note.toMap());
    } catch (e) {
      throw Exception('Error al actualizar nota: $e');
    }
  }

  Future<void> clearNotes() async {
    try {
      final snapshot = await _notes.get();
      for (final doc in snapshot.docs) {
        await _notes.doc(doc.id).delete();
      }
    } catch (e) {
      throw Exception('Error al limpiar notas: $e');
    }
  }

  Future<dynamic> searchNotes(String query) async {
    try {
      final snapshot = await _notes
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: query + '\uf8ff')
          .get();
      return snapshot.docs
          .map((doc) => Note.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar notas: $e');
    }
  }
}
