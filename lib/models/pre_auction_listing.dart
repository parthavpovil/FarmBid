class PreAuctionListing {
  final String id;
  final String sellerId;
  final String sellerName;
  final String productName;
  final String description;
  final String location;
  final DateTime expectedHarvestDate;
  final int estimatedQuantity;
  final String category;
  final List<String> interestedBuyerIds;
  final bool isListed; // becomes true when converted to auction
  final DateTime createdAt;

  PreAuctionListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.productName,
    required this.description,
    required this.location,
    required this.expectedHarvestDate,
    required this.estimatedQuantity,
    required this.category,
    required this.interestedBuyerIds,
    required this.isListed,
    required this.createdAt,
  });
}
