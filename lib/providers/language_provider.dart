import 'package:flutter/material.dart';

class LanguageProvider with ChangeNotifier {
  bool _isMalayalam = false;

  bool get isMalayalam => _isMalayalam;

  void toggleLanguage() {
    _isMalayalam = !_isMalayalam;
    notifyListeners();
  }

  String getText(String englishText) {
    if (!_isMalayalam) return englishText;
    
    // Add your English to Malayalam mappings here
    final Map<String, String> translations = {
      'Home': 'ഹോം',
      'Profile': 'പ്രൊഫൈൽ',
      'Auction': 'ലേലം',
      'Add Post': 'പോസ്റ്റ് ചേർക്കുക',
      'Future Harvests': 'ഭാവി വിളവുകൾ',
      'No posts yet': 'ഇതുവരെ പോസ്റ്റുകളൊന്നുമില്ല',
      'Add New Post': 'പുതിയ പോസ്റ്റ് ചേർക്കുക',
      'Featured Categories': 'പ്രമുഖ വിഭാഗങ്ങൾ',
      'Vegetables': 'പച്ചക്കറികൾ',
      'Fruits': 'പഴങ്ങൾ',
      'Rice': 'അരി',
      'Grains': 'ധാന്യങ്ങൾ',
      'Dairy': 'പാലുല്പന്നങ്ങൾ',
      'Others': 'മറ്റുള്ളവ',
      'Current Bid': 'നിലവിലെ ബിഡ്',
      'Place Bid': 'ബിഡ് ചെയ്യുക',
      'Your Bid': 'നിങ്ങളുടെ ബിഡ്',
      'Connect • Bid • Grow': 'കണക്റ്റ് • ബിഡ് • വളരുക',
      'Sign in with Google': 'Google ഉപയോഗിച്ച് സൈൻ ഇൻ ചെയ്യുക',
      'Welcome back,': 'സ്വാഗതം,',
      'Add Auction Item': 'ലേല ഇനം ചേർക്കുക',
      'Product Name': 'ഉൽപ്പന്നത്തിന്റെ പേര്',
      'Description': 'വിവരണം',
      'Location': 'സ്ഥലം',
      'Quantity': 'അളവ്',
      'Starting Bid': 'ആരംഭ ബിഡ്',
      'Category': 'വിഭാഗം',
      'Financial Assistance': 'സാമ്പത്തിക സഹായം',
      // Add more translations as needed
    };

    return translations[englishText] ?? englishText;
  }
}
