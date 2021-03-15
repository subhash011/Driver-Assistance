import 'package:http/http.dart' as http;

class Api {
  static String backend = "http://127.0.0.1:8000/api/";

  Future addObstacle(lat, lon, [desc=Null]) {
    var url = Uri.https(backend, 'coordinates');
    var response = http.post(url, body: {
      'lat': lat,
      'lon': lon,
      'desc': desc
    });
    return response;
  }

  // The route parameter is list of [lat, lon] (The route)
  // The response is list of [lat, lon] (Obstacles)
  Future getObstacles(List<List<double>> route) {
    var url = Uri.https(backend, 'obstacles');
    var response = http.post(url, body: route);
    return response;
  }

}