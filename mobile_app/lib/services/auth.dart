import 'dart:convert';

import 'package:PotholeDetector/shared_preference.dart';
import 'package:http/http.dart';

class Auth {
  static String root = "10.0.2.2:8000";

  static login(String email, String password) async {
    dynamic url = Uri.http(root, "/users/login/");
    Map map = new Map<String, String>();
    map['username'] = email;
    map['password'] = password;
    Response response = await post(url, body: map);
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  static signup(String email, String password) async {
    dynamic url = Uri.http(root, "/users/signup/");
    Map map = new Map<String, String>();
    map['username'] = email;
    map['password1'] = password;
    map['password2'] = password;
    Response response = await post(url, body: map);
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  static logout() async {
    await SharedPreference.clear();
  }
}
