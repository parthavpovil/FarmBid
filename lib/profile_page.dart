import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_item.dart';
import '../services/user_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, int> _userStats = {
    'activeAuctions': 0,
    'activeBids': 0,
    'completedDeals': 0
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    final user = _auth.currentUser;
    if (user != null) {
      final stats = await _userService.getUserStats(user.uid);
      setState(() {
        _userStats = stats;
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    // Add test auctions
    await firestore.collection('auctions').add({
      'sellerId': user.uid,
      'status': 'active',
      'name': 'Test Auction 1',
      'price': 100,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await firestore.collection('auctions').add({
      'sellerId': user.uid,
      'status': 'completed',
      'name': 'Test Auction 2',
      'price': 200,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Add test bids
    await firestore.collection('bids').add({
      'bidderId': user.uid,
      'status': 'active',
      'amount': 150,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Refresh stats
    _loadUserStats();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings page
            },
          ),
          IconButton(
            icon: Icon(Icons.add_box),
            onPressed: _addTestData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? 'No email',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard(
                            'Active\nAuctions',
                            _userStats['activeAuctions'].toString(),
                            Icons.gavel),
                        _buildStatCard(
                            'Active\nBids',
                            _userStats['activeBids'].toString(),
                            Icons.attach_money),
                        _buildStatCard(
                            'Completed\nDeals',
                            _userStats['completedDeals'].toString(),
                            Icons.done_all),
                      ],
                    ),
                  ),

                  // Recent Activity Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<ActivityItem>>(
                          stream:
                              _userService.getUserActivities(user?.uid ?? ''),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            final activities = snapshot.data ?? [];
                            return Column(
                              children: activities
                                  .map(
                                    (activity) => _buildActivityItem(
                                      activity.title,
                                      activity.subtitle,
                                      activity.getTimeAgo(),
                                      activity.getIcon(),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: Colors.green, size: 30),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
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
}
