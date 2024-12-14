import 'package:flutter/material.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'bid_page.dart';

class AuctionDetailPage extends StatelessWidget {
  final AuctionItem item;
  final AuctionService _auctionService = AuctionService();

  AuctionDetailPage({required this.item});

  Widget _buildImageCarousel() {
    if (item.images.isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return Container(
      height: 300,
      child: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(item.images[index]),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          );
        },
        itemCount: item.images.length,
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(),
        ),
        backgroundDecoration: BoxDecoration(
          color: Colors.black,
        ),
        pageController: PageController(),
      ),
    );
  }

  void _showCloseAuctionDialog(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser?.uid != item.sellerId) {
      return; // Only seller can close the auction
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Close Auction'),
          content: Text('Are you sure you want to close this auction?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _auctionService.closeAuction(item.id);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to previous screen
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final highestBid = item.bids.isNotEmpty
        ? item.bids.reduce((a, b) => a.amount > b.amount ? a : b)
        : null;
    final remainingTime = item.endTime.difference(DateTime.now());
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser?.uid == item.sellerId;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          if (isOwner && item.endTime.isBefore(DateTime.now()) && 
              item.status != AuctionStatus.closed)
            IconButton(
              icon: Icon(Icons.check_circle_outline),
              onPressed: () => _showCloseAuctionDialog(context),
              tooltip: 'Close Auction',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageCarousel(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Description:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text(item.description, style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Location', item.location),
                          _buildInfoRow('Quantity', item.quantity.toString()),
                          _buildInfoRow('Starting Bid', '₹${item.startingBid}'),
                          _buildInfoRow('Current Bid', '₹${item.currentBid}'),
                          _buildInfoRow('Time Remaining', 
                            remainingTime.isNegative ? 'Auction Ended' : 
                            '${remainingTime.inHours}h ${remainingTime.inMinutes.remainder(60)}m'),
                          _buildInfoRow('Highest Bidder', 
                            highestBid != null ? highestBid.bidderName : 'No bids yet'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Bid History:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: item.bids.length,
                      itemBuilder: (context, index) {
                        final bid = item.bids[index];
                        return ListTile(
                          leading: Icon(Icons.person_outline),
                          title: Text(bid.bidderName),
                          trailing: Text(
                            '₹${bid.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isOwner && item.status != AuctionStatus.closed ? Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Bid',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '₹${item.currentBid.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: remainingTime.isNegative ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BidPage(item: item),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  remainingTime.isNegative ? 'Auction Ended' : 'Place Bid',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ) : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}