import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import 'add_funds_screen.dart';
import 'history_page.dart';

class WalletScreen extends StatelessWidget {
  final WalletService _walletService = WalletService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Center(child: Text('Please login to view wallet'));

    return Scaffold(
      appBar: AppBar(
        title: Text('My Wallet'),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => HistoryPage(userId: user.uid)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddFundsScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<Wallet>(
        stream: _walletService.getWalletStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No wallet data found'));
          }

          final wallet = snapshot.data!;

          return Column(
            children: [
              _buildBalanceCard(wallet),
              Expanded(child: _buildTransactionsList(wallet.transactions)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(Wallet wallet) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Available Balance',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              '₹${wallet.availableBalance.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Locked Funds: ₹${wallet.lockedFunds.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<WalletTransaction> transactions) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          leading: _getTransactionIcon(transaction.type),
          title: Text(_getTransactionTitle(transaction)),
          subtitle: Text(transaction.description ?? ''),
          trailing: Text(
            '${transaction.type == 'deposit' ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: transaction.type == 'deposit' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Icon _getTransactionIcon(String type) {
    switch (type) {
      case 'deposit':
        return Icon(Icons.add_circle_outline, color: Colors.green);
      case 'lock':
        return Icon(Icons.lock_outline, color: Colors.orange);
      case 'transfer':
        return Icon(Icons.swap_horiz, color: Colors.blue);
      default:
        return Icon(Icons.money, color: Colors.grey);
    }
  }

  String _getTransactionTitle(WalletTransaction transaction) {
    switch (transaction.type) {
      case 'deposit':
        return 'Added Funds';
      case 'lock':
        return 'Locked for Bid';
      case 'transfer':
        return transaction.amount > 0 ? 'Received Payment' : 'Sent Payment';
      default:
        return 'Transaction';
    }
  }
}
