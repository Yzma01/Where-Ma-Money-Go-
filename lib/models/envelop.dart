import 'package:where_ma_money_go/models/envelop_transaction.dart';

class Envelop {
  final String id;
  final String name;
  final double amount;
  final List<EnvelopTransaction> transactions;
  final DateTime createdAt;

  Envelop({
    required this.id,
    required this.name,
    required this.amount,
    required this.transactions,
    required this.createdAt,
  });

  factory Envelop.fromMap(Map<String, dynamic> map, String id) {
    final rawTx = map['transactions'] as List<dynamic>? ?? [];
    return Envelop(
      id: id,
      name: map['name'] as String,
      amount: (map['amount'] as num? ?? 0).toDouble(),
      transactions: rawTx
          .map((t) => EnvelopTransaction.fromMap(t as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'transactions': transactions.map((t) => t.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  Envelop copyWith({
    String? id,
    String? name,
    double? amount,
    List<EnvelopTransaction>? transactions,
    DateTime? createdAt,
  }) => Envelop(
    id: id ?? this.id,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    transactions: transactions ?? this.transactions,
    createdAt: createdAt ?? this.createdAt,
  );
}
