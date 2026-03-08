import 'package:flutter/foundation.dart';
import 'package:where_ma_money_go/models/subcategory.dart';
import 'package:where_ma_money_go/models/category.dart';

class Bill {
  final Categories category;
  final Subcategory subcategory;
  final double amount;
  DateTime? date;
  String? month;
  final String id;
  final String type;
  final String cashFlow;

  Bill({
    required this.category,
    required this.subcategory,
    required this.amount,
    DateTime? date,
    String? month,
    required this.id,
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

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      category: Categories.fromMap(map['category']),
      subcategory: Subcategory.fromMap(map['subcategory']),
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      month: map['month'],
      id: map['id'],
      type: map['type'],
      cashFlow: map['cashFlow'],
    );
  }
}
