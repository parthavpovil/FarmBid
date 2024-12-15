import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FinancialAssistancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Assistance'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Container with gradient
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor,
                    Colors.green.shade50,
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.agriculture,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Farm Loans & Financial Support',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Supporting farmers with flexible financial solutions',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Loan Types Section
                  _buildSection(
                    context,
                    'Available Loan Types',
                    Icons.account_balance,
                    [
                      'Crop Loans',
                      'Equipment Purchase Loans',
                      'Land Development Loans',
                      'Farm Expansion Loans',
                    ],
                    Colors.blue.shade50,
                  ),
                  SizedBox(height: 24),

                  // Benefits Section
                  _buildSection(
                    context,
                    'Key Benefits',
                    Icons.star,
                    [
                      'Competitive interest rates',
                      'Flexible repayment terms',
                      'Quick processing',
                      'Minimal documentation',
                    ],
                    Colors.amber.shade50,
                  ),
                  SizedBox(height: 24),

                  // Requirements Section
                  _buildSection(
                    context,
                    'Basic Requirements',
                    Icons.assignment,
                    [
                      'Valid ID proof',
                      'Land ownership documents',
                      'Bank statements',
                      'Income proof/harvest records',
                    ],
                    Colors.green.shade50,
                  ),
                  SizedBox(height: 32),

                  // Contact Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade700,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.contact_support,
                              size: 48,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Ready to Get Started?',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Contact our financial advisors for personalized assistance and to start your application process.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildContactButton(
                                  icon: Icons.phone,
                                  label: 'Call Us',
                                  onPressed: () => _launchPhone('+1234567890'),
                                ),
                                _buildContactButton(
                                  icon: Icons.email,
                                  label: 'Email Us',
                                  onPressed: () => _launchEmail('support@farmbid.com'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<String> items, Color backgroundColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green, size: 20),
            SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    item,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _launchPhone(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _launchEmail(String email) async {
    final url = 'mailto:$email';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
