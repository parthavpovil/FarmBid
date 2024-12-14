import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ActivityItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String userId;

  ActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.userId,
  });

  IconData getIcon() {
    switch (type) {
      case 'bid':
        return Icons.gavel;
      case 'won':
        return Icons.emoji_events;
      case 'created':
        return Icons.add_circle;
      default:
        return Icons.event_note;
    }
  }

  String getTimeAgo() {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  factory ActivityItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityItem(
      id: doc.id,
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
    );
  }
}
