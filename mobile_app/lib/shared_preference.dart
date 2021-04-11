import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  static Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  static getPreferences() async {
    final SharedPreferences prefs = await _prefs;
    return prefs;
  }

  static setFirst() async {
    SharedPreferences prefs = await getPreferences();
    prefs.setBool('first', false);
  }

  static get first async {
    SharedPreferences prefs = await getPreferences();
    return prefs.getBool('first') ?? true;
  }

}