import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Api {
  static String backend = "10.0.2.2:8000";

  Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  addObstacle(lat, lon, [desc = ""]) async {
    var url = Uri.http(backend, '/api/coordinates/');
    var response = await http.post(url,
        body: jsonEncode(
            {'lat': lat.toString(), 'lon': lon.toString(), 'desc': desc}),
        headers: headers);
    return response;
  }

  // The route parameter is list of [lat, lon] (The route)
  // The response is list of [lat, lon] (Obstacles)
  getObstacles(List<List<double>> route) async {
    var url = Uri.http(backend, '/api/obstacles/');
    var response =
        await http.post(url, body: jsonEncode(route), headers: headers);
    return jsonDecode(response.body);
  }
}
