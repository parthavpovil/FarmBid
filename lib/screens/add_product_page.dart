import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/auction_item.dart';
import '../services/auction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'dart:io';

class AddProductPage extends StatefulWidget {
  final Map<String, dynamic>? preAuctionData;
  final String? preAuctionId;

  AddProductPage({this.preAuctionData, this.preAuctionId});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final AuctionService _auctionService = AuctionService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _startingBidController = TextEditingController();
  final TextEditingController _otherCategoryController =
      TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '1');
  String _selectedCategory = 'Vegetables'; // Default category
  Duration _auctionDuration = Duration(minutes: 1);
  String _selectedTimeUnit = 'minutes';
  bool _isLoadingLocation = false;
  double? _latitude;
  double? _longitude;

  List<String> categories = [
    'Vegetables',
    'Fruits',
    'Rice',
    'Grains',
    'Dairy',
    'Others',
  ];

  final ImagePicker _picker = ImagePicker();
  List<File> _selectedImages = [];
  bool _isUploading = false;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')),
      );
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permissions are denied')),
        );
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      if (!await _handleLocationPermission()) return;

      final position = await Geolocator.getCurrentPosition();
      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.locality}, ${place.administrativeArea}';
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get current location')),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _addAuctionItem() async {
    setState(() => _isUploading = true);

    try {
      final String name = _nameController.text;
      final String description = _descriptionController.text;
      final String location = _locationController.text;
      final int quantity = int.tryParse(_quantityController.text) ?? 0;
      final double startingBid =
          double.tryParse(_startingBidController.text) ?? 0.0;
      final String otherCategoryDescription =
          _selectedCategory == 'Others' ? _otherCategoryController.text : '';

      final int durationHours = int.tryParse(_durationController.text) ?? 12;
      _auctionDuration = Duration(hours: durationHours);

      if (name.isNotEmpty &&
          description.isNotEmpty &&
          location.isNotEmpty &&
          quantity > 0 &&
          startingBid > 0) {
        List<String> imageUrls = await _uploadImages();

        final User? user = FirebaseAuth.instance.currentUser;
        final String sellerId = user?.uid ?? 'unknown_user';
        final String sellerName = user?.displayName ?? 'Unknown';

        final newItem = AuctionItem(
          id: '',
          name: name,
          description: description,
          location: location,
          latitude: _latitude ?? 0,
          longitude: _longitude ?? 0,
          quantity: quantity,
          category: _selectedCategory,
          otherCategoryDescription: otherCategoryDescription,
          startingBid: startingBid,
          currentBid: startingBid,
          sellerId: sellerId,
          sellerName: sellerName,
          bids: [],
          endTime: DateTime.now().add(_auctionDuration),
          status: AuctionStatus.upcoming,
          images: imageUrls,
        );

        await _auctionService.addAuctionItem(newItem);

        if (widget.preAuctionId != null) {
          await FirebaseFirestore.instance
              .collection('pre_auction_listings')
              .doc(widget.preAuctionId)
              .update({'isListed': true});
        }

        Navigator.pop(context);
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    try {
      setState(() => _isUploading = true);
      
      for (var imageFile in _selectedImages) {
        final url = await CloudinaryService.uploadImage(imageFile);
        imageUrls.add(url);
        
        // Show upload progress
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uploaded ${imageUrls.length} of ${_selectedImages.length} images'),
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
      return imageUrls;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading images: $e')),
      );
      throw e;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedImages.length + 1,
        itemBuilder: (context, index) {
          if (index == _selectedImages.length) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add_photo_alternate, size: 40),
                ),
              ),
            );
          }
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _selectedImages.removeAt(index);
                    });
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDurationSelector() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _updateDuration(value);
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: _selectedTimeUnit,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: ['seconds', 'minutes', 'hours']
                .map((unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeUnit = value!;
                _updateDuration(_durationController.text);
              });
            },
          ),
        ),
      ],
    );
  }

  void _updateDuration(String value) {
    final duration = int.tryParse(value) ?? 0;
    setState(() {
      switch (_selectedTimeUnit) {
        case 'seconds':
          _auctionDuration = Duration(seconds: duration);
          break;
        case 'minutes':
          _auctionDuration = Duration(minutes: duration);
          break;
        case 'hours':
          _auctionDuration = Duration(hours: duration);
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.preAuctionData != null) {
      _nameController.text = widget.preAuctionData!['productName'] ?? '';
      _descriptionController.text = widget.preAuctionData!['description'] ?? '';
      _locationController.text = widget.preAuctionData!['location'] ?? '';
      _quantityController.text =
          widget.preAuctionData!['estimatedQuantity'].toString();
      _selectedCategory = widget.preAuctionData!['category'] ?? 'Vegetables';
      
      // Initialize duration with minutes as default
      _updateDuration(_durationController.text);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _startingBidController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Auction Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            SizedBox(height: 24),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.shopping_basket),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auction Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          onPressed: _getCurrentLocation,
                          icon: Icon(Icons.my_location),
                          tooltip: 'Get Current Location',
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.inventory),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _startingBidController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Starting Bid (₹)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Duration',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.timer),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _selectedTimeUnit,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: ['seconds', 'minutes', 'hours']
                                .map((unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedTimeUnit = value!;
                                _updateDuration(_durationController.text);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    if (_selectedCategory == 'Others') ...[
                      SizedBox(height: 16),
                      TextField(
                        controller: _otherCategoryController,
                        decoration: InputDecoration(
                          labelText: 'Specify Category',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.edit),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isUploading ? null : _addAuctionItem,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isUploading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Add Item',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
