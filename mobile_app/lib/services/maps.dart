import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  Set<Marker> markers = {};

  Future<String> getAddress(Position position) async {
    try {
      List<Placemark> p =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = p[0];
      String address =
          "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";
      return address;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    Codec codec = await instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))
        .buffer
        .asUint8List();
  }

  addMarker(Position coordinates,
      [bool isObstacle = true, String title = ""]) async {
    String address = await this.getAddress(coordinates);
    Marker marker = Marker(
      markerId: MarkerId('$coordinates'),
      position: LatLng(
        coordinates.latitude,
        coordinates.longitude,
      ),
      infoWindow: InfoWindow(
        title: title,
        snippet: address,
      ),
      icon: isObstacle
          ? BitmapDescriptor.fromBytes(
              await this.getBytesFromAsset("assets/images/dot.png", 24))
          : BitmapDescriptor.defaultMarker,
    );
    this.markers.add(marker);
  }

  getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }
}
