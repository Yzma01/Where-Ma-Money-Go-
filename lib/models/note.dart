import 'package:where_ma_money_go/models/bill.dart';
import 'package:where_ma_money_go/models/note_priority.dart';
import 'package:where_ma_money_go/models/recurrent.dart';

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String category;
  final bool hasDueDate;
  final bool hasBill;
  final NotePriority priority;
  Bill? bill;
  final bool isRecurrent;
  final bool isCompleted;
  Recurrent? recurrent;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.dueDate,
    this.category = '',
    this.hasDueDate = false,
    this.hasBill = false,
    this.priority = NotePriority.none,
    this.bill,
    this.isRecurrent = false,
    this.isCompleted = false,
    this.recurrent,
  });

  bool get isOverdue =>
      hasDueDate &&
      dueDate != null &&
      !isCompleted &&
      dueDate!.isBefore(DateTime.now());

  bool get isDueSoon {
    if (!hasDueDate || dueDate == null || isCompleted) return false;
    final diff = dueDate!.difference(DateTime.now()).inDays;
    return diff >= 0 && diff <= 3;
  }

  factory Note.fromMap(Map<String, dynamic> map, String id) {
    return Note(
      id: id,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'] as String)
          : null,
      category: map['category'] as String? ?? '',
      hasDueDate: map['hasDueDate'] as bool? ?? false,
      hasBill: map['hasBill'] as bool? ?? false,
      priority: NotePriorityExt.fromInt(map['priority'] as int?),
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
      'dueDate': dueDate?.toIso8601String(),
      'category': category,
      'hasDueDate': hasDueDate,
      'hasBill': hasBill,
      'priority': priority.value,
      'bill': bill?.toMap(),
      'isRecurrent': isRecurrent,
      'isCompleted': isCompleted,
      'recurrent': recurrent?.toMap(),
    };
  }
}
