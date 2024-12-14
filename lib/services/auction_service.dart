import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auction_item.dart';

class AuctionService {
  final CollectionReference _auctionCollection =
      FirebaseFirestore.instance.collection('auction_items');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAuctionItem(AuctionItem item) async {
    await _auctionCollection.add({
      'name': item.name,
      'description': item.description,
      'location': item.location,
      'quantity': item.quantity,
      'category': item.category,
      'otherCategoryDescription': item.otherCategoryDescription,
      'startingBid': item.startingBid,
      'currentBid': item.currentBid,
      'sellerId': item.sellerId,
      'sellerName': item.sellerName,
      'bids': [],
      'endTime': item.endTime.toIso8601String(),
      'status': item.status.toString(),
      'images': item.images,
    });

    await createActivity(
      item.sellerId,
      'created',
      'Created new auction',
      'Listed ${item.name} for auction',
    );
  }

  Stream<List<AuctionItem>> getAuctionItems() {
    return _auctionCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AuctionItem(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          quantity: data['quantity'] ?? 0,
          category: data['category'] ?? '',
          otherCategoryDescription: data['otherCategoryDescription'] ?? '',
          startingBid: (data['startingBid'] ?? 0).toDouble(),
          currentBid: (data['currentBid'] ?? 0).toDouble(),
          sellerId: data['sellerId'] ?? '',
          sellerName: data['sellerName'] ?? '',
          bids: ((data['bids'] ?? []) as List)
              .map((bid) => Bid(
                    bidderId: bid['bidderId'] ?? '',
                    bidderName: bid['bidderName'] ?? '',
                    amount: (bid['amount'] ?? 0).toDouble(),
                  ))
              .toList(),
          endTime: DateTime.parse(data['endTime']),
          status: AuctionStatus.values.firstWhere(
            (e) => e.toString() == data['status'],
            orElse: () => AuctionStatus.upcoming,
          ),
          images: List<String>.from(data['images'] ?? []),
        );
      }).toList();
    });
  }

  Future<void> placeBid(String itemId, Bid bid) async {
    // First get the item details
    final itemDoc = await _auctionCollection.doc(itemId).get();
    final itemData = itemDoc.data() as Map<String, dynamic>;
    final itemName = itemData['name'];

    await _auctionCollection.doc(itemId).update({
      'currentBid': bid.amount,
      'bids': FieldValue.arrayUnion([
        {
          'bidderId': bid.bidderId,
          'bidderName': bid.bidderName,
          'amount': bid.amount,
        }
      ]),
    });

    // Create activity with the item name
    await createActivity(
      bid.bidderId,
      'bid',
      'Placed a bid',
      'You bid ₹${bid.amount} on $itemName',
    );
  }

  Future<void> closeAuction(String itemId) async {
    await _auctionCollection.doc(itemId).delete();
  }

  Future<void> checkExpiredAuctions() async {
    final now = DateTime.now();
    final snapshot = await _auctionCollection.get();
    for (var doc in snapshot.docs) {
      final endTime = DateTime.parse(doc['endTime']);
      if (now.isAfter(endTime)) {
        // Logic to determine the highest bidder
        final bids = doc['bids'] as List;
        if (bids.isNotEmpty) {
          final highestBid =
              bids.reduce((a, b) => a['amount'] > b['amount'] ? a : b);
          // You can handle the logic to notify the highest bidder or process the sale
        }
        await closeAuction(doc.id);
      }
    }
  }

  Future<void> createActivity(
      String userId, String type, String title, String subtitle) async {
    await _firestore.collection('activities').add({
      'userId': userId,
      'type': type, // 'bid', 'created', 'won'
      'title': title,
      'subtitle': subtitle,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
