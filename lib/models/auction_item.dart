enum AuctionStatus {
  live,
  closed,
  upcoming,
}

class AuctionItem {
  final String id;
  final String name;
  final String description;
  final String location;
  final int quantity;
  final String category;
  final String otherCategoryDescription;
  final double startingBid;
  double currentBid;
  final String sellerId;
  final String sellerName;
  final List<Bid> bids;
  final DateTime endTime;
  final AuctionStatus status;

  AuctionItem({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.quantity,
    required this.category,
    required this.otherCategoryDescription,
    required this.startingBid,
    required this.currentBid,
    required this.sellerId,
    required this.sellerName,
    required this.bids,
    required this.endTime,
    required this.status,
  });
}

class Bid {
  final String bidderId;
  final String bidderName;
  final double amount;

  Bid({
    required this.bidderId,
    required this.bidderName,
    required this.amount,
  });
} 