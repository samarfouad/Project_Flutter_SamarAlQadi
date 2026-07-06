import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveSession(String role, String id) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("role", role);
  await prefs.setString("userId", id);
}

Future<Map<String, String>?> getSession() async {
  final prefs = await SharedPreferences.getInstance();
  final hasSession = prefs.containsKey("role") && prefs.containsKey("userId");
  if (!hasSession) return null;
  return {
    "role": prefs.getString("role") ?? "",
    "userId": prefs.getString("userId") ?? "",
  };
}

Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("role");
  await prefs.remove("userId");
}
