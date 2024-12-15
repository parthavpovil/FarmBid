import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatelessWidget {
  final String userId;

  HistoryPage({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recharge History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recharges')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No recharge history found.'));
          }

          final recharges = snapshot.data!.docs;

          return ListView.builder(
            itemCount: recharges.length,
            itemBuilder: (context, index) {
              final recharge = recharges[index];
              return ListTile(
                title: Text('₹${recharge['amount']}'),
                subtitle: Text(recharge['timestamp'].toDate().toString()),
              );
            },
          );
        },
      ),
    );
  }
}
