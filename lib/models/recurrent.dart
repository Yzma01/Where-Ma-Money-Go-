class Recurrent {
  final String id;
  final String title;
  final DateTime startDate;
  final DateTime? endDate;
  final String frequency;
  final DateTime? nextDueDate; // ← próxima fecha de pago

  Recurrent({
    required this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    required this.frequency,
    this.nextDueDate,
  });

  /// Calcula la próxima fecha de pago a partir de una fecha de pago dada
  static DateTime calcNextDue(DateTime from, String frequency) {
    switch (frequency) {
      case 'daily':
        return DateTime(from.year, from.month, from.day + 1);
      case 'weekly':
        return DateTime(from.year, from.month, from.day + 7);
      case 'monthly':
        return DateTime(from.year, from.month + 1, from.day);
      case 'yearly':
        return DateTime(from.year + 1, from.month, from.day);
      default:
        return DateTime(from.year, from.month + 1, from.day);
    }
  }

  /// Días de anticipación para reactivar la nota antes del vencimiento
  static int leadDays(String frequency) {
    switch (frequency) {
      case 'daily':
        return 0; // se activa el mismo día
      case 'weekly':
        return 3;
      case 'monthly':
        return 7;
      case 'yearly':
        return 30;
      default:
        return 7;
    }
  }

  /// ¿Debe mostrarse la nota como pendiente hoy?
  bool get isDue {
    final due = nextDueDate;
    if (due == null) return true; // nunca se ha pagado → siempre activa
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final dueDate = DateTime(due.year, due.month, due.day);
    final lead = leadDays(frequency);
    // Activar `lead` días antes de la fecha de pago
    return todayDate.isAfter(dueDate.subtract(Duration(days: lead + 1)));
  }

  factory Recurrent.fromMap(Map<String, dynamic> json) {
    return Recurrent(
      id: json['id'] as String,
      title: json['title'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      frequency: json['frequency'] as String,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'frequency': frequency,
      'nextDueDate': nextDueDate?.toIso8601String(),
    };
  }

  Recurrent copyWith({DateTime? nextDueDate}) {
    return Recurrent(
      id: id,
      title: title,
      startDate: startDate,
      endDate: endDate,
      frequency: frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
    );
  }
}
