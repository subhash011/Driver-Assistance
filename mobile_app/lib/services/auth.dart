import 'package:PotholeDetector/shared_preference.dart';
import 'package:http/http.dart' as http;

class Auth {
  static login(String email, String password) {}
  static logout() async {
    await SharedPreference.clear();
  }
}
