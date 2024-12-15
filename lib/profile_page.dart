import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_item.dart';
import '../services/user_service.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';
import '../screens/wallet_screen.dart';
import '../screens/interests_page.dart';
import '../screens/financial_assistance_page.dart';

class ProfilePage extends StatelessWidget {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WalletService _walletService = WalletService();

  Widget _buildWalletCard(BuildContext context, Wallet wallet) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => WalletScreen()),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              SizedBox(height: 8),
              Text(
                '₹${wallet.availableBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              if (wallet.lockedFunds.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  'Locked in bids: ₹${wallet.lockedFunds.values.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return Center(child: Text('Please login to view profile'));

    return Scaffold(
      body: StreamBuilder<Wallet>(
        stream: _walletService.getWalletStream(user.uid),
        builder: (context, walletSnapshot) {
          return ListView(
            children: [
              // Profile header section
              _buildProfileHeader(user),

              // Wallet section
              if (walletSnapshot.hasData)
                _buildWalletCard(context, walletSnapshot.data!),

              // Rest of your profile sections
              _buildMenuSection(context),
              _buildActivitySection(user.uid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          user.photoURL != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(user.photoURL!),
                  radius: 40,
                )
              : CircleAvatar(
                  child: Icon(Icons.account_circle, size: 50),
                  radius: 40,
                ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName ?? 'User',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email ?? '',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Interests Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InterestsPage(),
                ),
              );
            },
            icon: Icon(Icons.favorite),
            label: Text('My Interests'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(16),
              minimumSize: Size.fromHeight(50),
            ),
          ),

          SizedBox(height: 16),

          // Financial Assistance Button
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FinancialAssistancePage(),
                ),
              );
            },
            icon: Icon(Icons.account_balance),
            label: Text('Apply for Financial Assistance'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.all(16),
              minimumSize: Size.fromHeight(50),
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySection(String userId) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          StreamBuilder<List<ActivityItem>>(
            stream: _userService.getUserActivities(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              final activities = snapshot.data ?? [];
              if (activities.isEmpty) {
                return Center(child: Text('No recent activity'));
              }

              return Column(
                children: activities.map((activity) {
                  return _buildActivityItem(
                    activity.title,
                    activity.subtitle,
                    _formatTimestamp(activity.timestamp),
                    _getActivityIcon(activity.type),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'bid':
        return Icons.gavel;
      case 'created':
        return Icons.add_circle;
      case 'won':
        return Icons.emoji_events;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
