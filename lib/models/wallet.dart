class Wallet {
  final String userId;
  final double balance;
  final List<WalletTransaction> transactions;
  final Map<String, double> lockedFunds; // auctionId -> amount

  Wallet({
    required this.userId,
    required this.balance,
    required this.transactions,
    required this.lockedFunds,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'lockedFunds': lockedFunds,
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      userId: map['userId'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      transactions: ((map['transactions'] ?? []) as List)
          .map((t) => WalletTransaction.fromMap(t))
          .toList(),
      lockedFunds: Map<String, double>.from(map['lockedFunds'] ?? {}),
    );
  }

  double get availableBalance =>
      balance - lockedFunds.values.fold(0, (a, b) => a + b);
}

class WalletTransaction {
  final String id;
  final String type; // 'deposit', 'withdrawal', 'lock', 'unlock', 'transfer'
  final double amount;
  final String? description;
  final DateTime timestamp;
  final String? relatedAuctionId;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.description,
    required this.timestamp,
    this.relatedAuctionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'relatedAuctionId': relatedAuctionId,
    };
  }

  factory WalletTransaction.fromMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'],
      type: map['type'],
      amount: map['amount'].toDouble(),
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
      relatedAuctionId: map['relatedAuctionId'],
    );
  }
}
