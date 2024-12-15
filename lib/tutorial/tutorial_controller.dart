import 'package:shared_preferences/shared_preferences.dart';

class TutorialController {
  static const String _hasSeenHomeTutorialKey = 'has_seen_home_tutorial';
  static const String _hasSeenAuctionTutorialKey = 'has_seen_auction_tutorial';
  
  static Future<bool> hasSeenHomeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenHomeTutorialKey) ?? false;
  }
  
  static Future<bool> hasSeenAuctionTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenAuctionTutorialKey) ?? false;
  }
  
  static Future<void> markHomeTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenHomeTutorialKey, true);
  }
  
  static Future<void> markAuctionTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenAuctionTutorialKey, true);
  }
}