import 'package:flutter/material.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BidPage extends StatefulWidget {
  final AuctionItem item;

  BidPage({required this.item});

  @override
  _BidPageState createState() => _BidPageState();
}

class _BidPageState extends State<BidPage> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _bidController = TextEditingController();

  void _placeBid() {
    final double newBid = double.tryParse(_bidController.text) ?? 0.0;
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to place a bid')),
      );
      return;
    }

    if (user.uid == widget.item.sellerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You cannot bid on your own product.')),
      );
      return;
    }

    if (newBid > widget.item.currentBid) {
      final bid = Bid(
        bidderId: user.uid,
        bidderName: user.displayName ?? 'Unknown User',
        amount: newBid,
      );
      _auctionService.placeBid(widget.item.id, bid);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bid must be higher than current bid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bid on ${widget.item.name}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Current Bid: \$${widget.item.currentBid}'),
            TextField(
              controller: _bidController,
              decoration: InputDecoration(labelText: 'Your Bid'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _placeBid,
              child: Text('Place Bid'),
            ),
            SizedBox(height: 20),
            Text('Bids:'),
            Expanded(
              child: ListView.builder(
                itemCount: widget.item.bids.length,
                itemBuilder: (context, index) {
                  final bid = widget.item.bids[index];
                  return ListTile(
                    title: Text('${bid.bidderName} bid: \$${bid.amount}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
