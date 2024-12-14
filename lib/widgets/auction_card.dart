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

  Widget _buildImage() {
    if (item.images.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    return Container(
      height: 120,
      width: double.infinity,
      child: Image.network(
        item.images[0], // Show first image
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: Icon(Icons.error_outline, color: Colors.red),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = item.endTime.difference(DateTime.now());
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item.currentBid}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        remainingTime.isNegative ? 'Ended' : 
                        '${remainingTime.inHours}h ${remainingTime.inMinutes.remainder(60)}m',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 