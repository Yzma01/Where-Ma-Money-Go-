import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/recurrent.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool hasBill;
  Bill? bill;
  final bool isRecurrent;
  final bool isCompleted;
  Recurrent? recurrent;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.hasBill = false,
    this.bill,
    this.isRecurrent = false,
    this.isCompleted = false,
    this.recurrent,
  });

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      hasBill: map['hasBill'] as bool? ?? false,
      // ✅ Usar Bill.fromMapData — el bill está embebido como Map, no como doc
      bill: map['bill'] != null
          ? Bill.fromMapData(map['bill'] as Map<String, dynamic>)
          : null,
      isRecurrent: map['isRecurrent'] as bool? ?? false,
      isCompleted: map['isCompleted'] as bool? ?? false,
      recurrent: map['recurrent'] != null
          ? Recurrent.fromMap(map['recurrent'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'hasBill': hasBill,
      'bill': bill?.toMap(),
      'isRecurrent': isRecurrent,
      'isCompleted': isCompleted,
      'recurrent': recurrent?.toMap(),
    };
  }
}
