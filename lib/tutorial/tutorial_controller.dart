 import 'package:shared_preferences/shared_preferences.dart';

class TutorialController {
  static const String _hasSeenTutorialKey = 'has_seen_tutorial';
  
  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenTutorialKey) ?? false;
  }
  
  static Future<void> markTutorialAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenTutorialKey, true);
  }
}