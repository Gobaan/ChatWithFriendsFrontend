import 'package:shared_preferences/shared_preferences.dart';

Future<void> storeInfo(String key, String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, url);
}

Future<String?> getStoredInfo(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}
