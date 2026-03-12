class EnvelopTransaction {
  final String id;
  final double amount;
  final String type; // 'deposit' | 'withdraw'
  final String note;
  final DateTime date;

  EnvelopTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.note,
    required this.date,
  });

  bool get isDeposit => type == 'deposit';

  factory EnvelopTransaction.fromMap(Map<String, dynamic> map) {
    return EnvelopTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      note: map['note'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'type': type,
    'note': note,
    'date': date.toIso8601String(),
  };
}
