import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:where_ma_money_go/models/subcategory.dart';

class Categories {
  final String name;
  final String? id;
  final String? icon;
  final List<Subcategory>? subcategories;

  Categories({required this.name, this.id, this.icon, this.subcategories});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'id': id,
      'icon': icon,
      'subcategories': subcategories?.map((s) => s.toMap()).toList(),
    };
  }

  /// Usado al leer documentos de la colección 'categories' en Firestore
  factory Categories.fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    return Categories(
      name: map['name'],
      id: doc.id,
      icon: map['icon'],
      subcategories: map['subcategories'] != null
          ? List<Subcategory>.from(
              map['subcategories'].map((s) => Subcategory.fromMap(s)),
            )
          : null,
    );
  }

  /// Usado al leer la categoría embebida dentro de un documento Bill
  factory Categories.fromMapData(Map<String, dynamic> map) {
    return Categories(
      name: map['name'],
      id: map['id'],
      icon: map['icon'],
      subcategories: map['subcategories'] != null
          ? List<Subcategory>.from(
              map['subcategories'].map((s) => Subcategory.fromMap(s)),
            )
          : null,
    );
  }
}
