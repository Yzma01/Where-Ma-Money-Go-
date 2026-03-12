class Saving {
  final String id;
  final String name;
  final double goalAmount;
  final double currentAmount;
  final DateTime dueDate;
  bool isCompleted = false;

  Saving({
    required this.id,
    required this.name,
    required this.goalAmount,
    required this.currentAmount,
    required this.dueDate,
    this.isCompleted = false,
  });

  factory Saving.fromMap(Map<String, dynamic> json, String id) {
    return Saving(
      id: id,
      name: json['name'],
      goalAmount: json['goalAmount'],
      currentAmount: json['currentAmount'],
      dueDate: DateTime.parse(json['dueDate']),
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'goalAmount': goalAmount,
      'currentAmount': currentAmount,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  Saving copyWith({
    String? id,
    String? name,
    double? goalAmount,
    double? currentAmount,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Saving(
      id: id ?? this.id,
      name: name ?? this.name,
      goalAmount: goalAmount ?? this.goalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get isNotEmpty => id.isNotEmpty && name.isNotEmpty && !isCompleted;
}
