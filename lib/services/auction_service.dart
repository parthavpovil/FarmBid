import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/auction_item.dart';
import '../services/wallet_service.dart';

class AuctionService {
  final CollectionReference _auctionCollection =
      FirebaseFirestore.instance.collection('auction_items');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addAuctionItem(AuctionItem item) async {
    await _auctionCollection.add({
      'name': item.name,
      'description': item.description,
      'location': item.location,
      'latitude': item.latitude,
      'longitude': item.longitude,
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
          latitude: (data['latitude'] ?? 0).toDouble(),
          longitude: (data['longitude'] ?? 0).toDouble(),
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
    final walletService = WalletService();
    final doc = await _auctionCollection.doc(itemId).get();
    final data = doc.data() as Map<String, dynamic>;
    
    // Find highest bidder
    final bids = List<Map<String, dynamic>>.from(data['bids'] ?? []);
    if (bids.isNotEmpty) {
      // Get highest bid
      final highestBid = bids.reduce((a, b) => 
        (a['amount'] as num) > (b['amount'] as num) ? a : b);
      
      // Update auction with winner info
      await _auctionCollection.doc(itemId).update({
        'status': AuctionStatus.closed.toString(),
        'winnerId': highestBid['bidderId'],
        'winnerName': highestBid['bidderName'],
        'finalBid': highestBid['amount'],
      });

      // Create activity for winner
      await createActivity(
        highestBid['bidderId'],
        'won',
        'Won Auction!',
        'You won the auction for ${data['name']} at ₹${highestBid['amount']}',
      );
    } else {
      // No bids, just close the auction
      await _auctionCollection.doc(itemId).update({
        'status': AuctionStatus.closed.toString(),
      });
    }
  }

  Future<void> checkExpiredAuctions() async {
    final now = DateTime.now();
    final snapshot = await _auctionCollection
        .where('status', isNotEqualTo: AuctionStatus.closed.toString())
        .get();
        
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final endTime = DateTime.parse(data['endTime']);
      if (now.isAfter(endTime)) {
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

  Stream<List<AuctionItem>> getWonAuctions(String userId) {
    return _auctionCollection
        .where('status', isEqualTo: AuctionStatus.closed.toString())
        .where('winnerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AuctionItem(
          id: doc.id,
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          location: data['location'] ?? '',
          latitude: (data['latitude'] ?? 0).toDouble(),
          longitude: (data['longitude'] ?? 0).toDouble(),
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
}
