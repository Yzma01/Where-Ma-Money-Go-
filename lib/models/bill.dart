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

  Bill({
    required this.category,
    required this.subcategory,
    required this.amount,
    DateTime? date,
    String? month,
    this.id,
    required this.type,
    required this.cashFlow,
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
    };
  }

  factory Bill.fromMap(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data();
    return Bill(
      // Usar fromMapData porque 'category' es un Map embebido, no un documento
      category: Categories.fromMapData(map['category'] as Map<String, dynamic>),
      subcategory: Subcategory.fromMap(
        map['subcategory'] as Map<String, dynamic>,
      ),
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      month: map['month'] as String?,
      id: doc.id,
      type: map['type'] as String,
      cashFlow: map['cashFlow'] as String,
    );
  }
}
