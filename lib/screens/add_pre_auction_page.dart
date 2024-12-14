import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pre_auction_service.dart';
import '../models/pre_auction_listing.dart';

class AddPreAuctionPage extends StatefulWidget {
  @override
  _AddPreAuctionPageState createState() => _AddPreAuctionPageState();
}

class _AddPreAuctionPageState extends State<AddPreAuctionPage> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _expectedHarvestDate;
  String _selectedCategory = 'Vegetables';
  final PreAuctionService _preAuctionService = PreAuctionService();

  List<String> categories = [
    'Vegetables',
    'Fruits',
    'Rice',
    'Grains',
    'Dairy',
    'Others',
  ];

  Future<void> _submitPreAuction() async {
    if (_formKey.currentState!.validate() && _expectedHarvestDate != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final listing = PreAuctionListing(
        id: '',
        sellerId: user.uid,
        sellerName: user.displayName ?? 'Unknown Farmer',
        productName: _productNameController.text,
        description: _descriptionController.text,
        location: 'Location', // You can add location picker here
        expectedHarvestDate: _expectedHarvestDate!,
        estimatedQuantity: int.parse(_quantityController.text),
        category: _selectedCategory,
        interestedBuyerIds: [],
        isListed: false,
        createdAt: DateTime.now(),
      );

      await _preAuctionService.createPreAuctionListing(listing);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Future Harvest'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _productNameController,
              decoration: InputDecoration(labelText: 'Product Name'),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter product name' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter description' : null,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(labelText: 'Estimated Quantity (kg)'),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Please enter quantity' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: 'Category'),
              items: categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            SizedBox(height: 16),
            ListTile(
              title: Text('Expected Harvest Date'),
              subtitle: Text(
                _expectedHarvestDate?.toString().split(' ')[0] ?? 'Not set',
              ),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(Duration(days: 90)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _expectedHarvestDate = date);
                }
              },
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitPreAuction,
              child: Text('Add Future Harvest'),
            ),
          ],
        ),
      ),
    );
  }
}
