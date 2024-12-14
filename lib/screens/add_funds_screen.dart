import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/wallet_service.dart';
import '../screens/confirmation_page.dart';

class AddFundsScreen extends StatefulWidget {
  @override
  _AddFundsScreenState createState() => _AddFundsScreenState();
}

class _AddFundsScreenState extends State<AddFundsScreen> {
  late Razorpay _razorpay;
  final _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isProcessing = false;
  final List<double> _quickAmounts = [100, 500, 1000, 5000];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final amount = double.parse(_amountController.text);
      await _walletService.addFunds(user.uid, amount);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(
              message: 'Successfully added ₹${amount.toStringAsFixed(2)} to your wallet!',
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding funds: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Payment failed: ${response.message}\nCode: ${response.code}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('External wallet selected: ${response.walletName}')),
    );
  }

  void _startPayment() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    var options = {
      'key': 'rzp_test_OjQrjIa0tfNFh5',
      'amount': (amount * 100).toInt(),
      'name': 'FarmBid',
      'description': 'Add funds to wallet',
      'prefill': {
        'contact': user.phoneNumber ?? '',
        'email': user.email ?? '',
      },
      'theme': {
        'color': '#4CAF50',
      }
    };
    try {
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Funds')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            Text(
              'Quick Add',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickAmounts
                  .map((amount) => ElevatedButton(
                        onPressed: () =>
                            _amountController.text = amount.toString(),
                        child: Text('₹$amount'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black87,
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isProcessing ? null : _startPayment,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: _isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Add Funds', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Note: Funds will be added to your wallet after successful payment',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
