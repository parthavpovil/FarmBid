import 'package:flutter/material.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'add_product_page.dart';
import 'bid_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auction_detail_page.dart';
import '../widgets/auction_card.dart';

class AuctionPage extends StatefulWidget {
  @override
  _AuctionPageState createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> with SingleTickerProviderStateMixin {
  final AuctionService _auctionService = AuctionService();
  String _searchQuery = '';
  String? _selectedCategory;
  List<String> categories = [
    'All',
    'Vegetables',
    'Fruits',
    'Rice',
    'Grains',
    'Dairy',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text('FarmBid Market'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: Icon(Icons.gavel),
                text: 'Available Auctions',
              ),
              Tab(
                icon: Icon(Icons.inventory),
                text: 'My Auctions',
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle_outline),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductPage()),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildAvailableAuctionsTab(),
            _buildMyAuctionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableAuctionsTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<List<AuctionItem>>(
      stream: _auctionService.getAuctionItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allAuctionItems = snapshot.data ?? [];
        // Filter out auctions owned by the current user
        final auctionItems = allAuctionItems
            .where((item) => item.sellerId != currentUser?.uid)
            .toList();
        
        if (auctionItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No auctions available'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: auctionItems.length,
          itemBuilder: (context, index) {
            final item = auctionItems[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailPage(item: item),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image section
                    Container(
                      width: 120,
                      height: 120,
                      child: item.images.isNotEmpty
                          ? Image.network(
                              item.images[0],
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
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                    ),
                    // Content section
                    Expanded(
                      child: Padding(
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
                                  _formatRemainingTime(item.endTime.difference(DateTime.now())),
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search Auctions',
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          DropdownButton<String>(
            value: _selectedCategory,
            hint: Text('Select Category'),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCategory = newValue;
              });
            },
            items: categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCloseAuctionDialog(BuildContext context, String itemId, DateTime endTime) {
    final remainingTime = endTime.difference(DateTime.now());

    if (remainingTime.isNegative) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Close Auction'),
            content: Text('Are you sure you want to close this auction?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _auctionService.closeAuction(itemId);
                  Navigator.of(context).pop(); // Close the dialog
                  setState(() {}); // Refresh the UI
                },
                child: Text('Confirm'),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cannot Close Auction'),
            content: Text('You can only close the auction after it has ended.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _getStatusIndicator(AuctionItem item) {
    Color color;
    if (item.endTime.isAfter(DateTime.now())) {
      color = Colors.red; // Active auction
    } else if (item.status == AuctionStatus.closed) {
      color = Colors.green; // Auction completely over
    } else {
      color = Colors.yellow; // Bidding time over but unsold
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMyAuctionsTab() {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<List<AuctionItem>>(
      stream: _auctionService.getAuctionItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final auctionItems = snapshot.data ?? [];
        final myItems = auctionItems
            .where((item) => item.sellerId == currentUser?.uid)
            .toList();

        if (myItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No auctions yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductPage()),
                  ),
                  icon: Icon(Icons.add),
                  label: Text('Add New Auction'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: myItems.length,
          itemBuilder: (context, index) {
            final item = myItems[index];
            final remainingTime = item.endTime.difference(DateTime.now());
            
            return Card(
              child: ListTile(
                title: Text(
                  item.name,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Bid: ₹${item.currentBid.toStringAsFixed(2)}'),
                    Text('Time Remaining: ${_formatRemainingTime(remainingTime)}'),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _getStatusIndicator(item),
                    SizedBox(width: 8),
                    if (item.endTime.isBefore(DateTime.now()) && 
                        item.status != AuctionStatus.closed)
                      IconButton(
                        icon: Icon(Icons.check_circle_outline),
                        onPressed: () => _showCloseAuctionDialog(
                          context,
                          item.id,
                          item.endTime,
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AuctionDetailPage(item: item),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatRemainingTime(Duration duration) {
    if (duration.isNegative) {
      return 'Ended';
    }
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
