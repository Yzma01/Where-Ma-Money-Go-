import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/models/category.dart';

class Bill {
  final Categories category;
  final Subcategory subcategory;
  final double amount;
  DateTime? date;
  String? month;
  String? id;
  final String type;
  final String cashFlow;

  /// ID del Saving asociado (solo cuando la categoría es "ahorro")
  final String? savingId;

  Bill({
    required this.category,
    required this.subcategory,
    required this.amount,
    DateTime? date,
    String? month,
    this.id,
    required this.type,
    required this.cashFlow,
    this.savingId,
  }) : date = date ?? DateTime.now(),
       month = month?.isEmpty ?? true ? DateTime.now().month.toString() : month;

  Map<String, dynamic> toMap() {
    return {
      'category': category.toMap(),
      'subcategory': subcategory.toMap(),
      'amount': amount,
      'date': date?.toIso8601String(),
      'month': month,
      'id': id,
      'type': type,
      'cashFlow': cashFlow,
      if (savingId != null) 'savingId': savingId,
    };
  }

  /// Para bills guardados como documento Firestore (collection bills/)
  factory Bill.fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return Bill.fromMapData(doc.data(), id: doc.id);
  }

  /// Para bills embebidos como Map dentro de una nota
  factory Bill.fromMapData(Map<String, dynamic> map, {String? id}) {
    return Bill(
      category: Categories.fromMapData(map['category'] as Map<String, dynamic>),
      subcategory: Subcategory.fromMap(
        map['subcategory'] as Map<String, dynamic>,
      ),
      amount: (map['amount'] as num).toDouble(),
      date: map['date'] != null ? DateTime.parse(map['date'] as String) : null,
      month: map['month'] as String?,
      id: id ?? map['id'] as String?,
      type: map['type'] as String,
      cashFlow: map['cashFlow'] as String,
      savingId: map['savingId'] as String?,
    );
  }
}
