import 'package:flutter/material.dart';
import '../models/auction_item.dart';

class AuctionCard extends StatelessWidget {
  final AuctionItem item;
  final VoidCallback onTap;

  const AuctionCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final remainingTime = item.endTime.difference(DateTime.now());
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(remainingTime),
                ],
              ),
              SizedBox(height: 8),
              _buildInfoRow(
                Icons.monetization_on,
                'Current Bid: ₹${item.currentBid.toStringAsFixed(2)}',
              ),
              SizedBox(height: 4),
              _buildInfoRow(
                Icons.person,
                'Seller: ${item.sellerName}',
              ),
              SizedBox(height: 4),
              _buildInfoRow(
                Icons.timer,
                'Time Left: ${_formatRemainingTime(remainingTime)}',
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: remainingTime.inSeconds > 0
                    ? remainingTime.inSeconds /
                        item.endTime.difference(DateTime.now()).inSeconds
                    : 0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  remainingTime.inHours > 24
                      ? Colors.green
                      : remainingTime.inHours > 6
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Duration remainingTime) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: remainingTime.inHours > 24
            ? Colors.green[100]
            : remainingTime.inHours > 6
                ? Colors.orange[100]
                : Colors.red[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        remainingTime.inHours > 24
            ? 'Active'
            : remainingTime.inHours > 6
                ? 'Ending Soon'
                : 'Last Hours',
        style: TextStyle(
          color: remainingTime.inHours > 24
              ? Colors.green[900]
              : remainingTime.inHours > 6
                  ? Colors.orange[900]
                  : Colors.red[900],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
} 