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
    });

    // Create activity record for creating auction
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
        return AuctionItem(
          id: doc.id,
          name: doc['name'],
          description: doc['description'],
          location: doc['location'],
          quantity: doc['quantity'],
          category: doc['category'],
          otherCategoryDescription: doc['otherCategoryDescription'],
          startingBid: doc['startingBid'],
          currentBid: doc['currentBid'],
          sellerId: doc['sellerId'],
          sellerName: doc['sellerName'],
          bids: (doc['bids'] as List).map((bid) {
            return Bid(
              bidderId: bid['bidderId'],
              bidderName: bid['bidderName'],
              amount: bid['amount'],
            );
          }).toList(),
          endTime: DateTime.parse(doc['endTime']),
          status: AuctionStatus.values
              .firstWhere((e) => e.toString() == doc['status']),
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
