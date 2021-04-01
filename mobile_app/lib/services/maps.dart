import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:PotholeDetector/services/api.dart';
import 'package:PotholeDetector/widgets/maps/maps.dart';
import 'package:PotholeDetector/widgets/maps/network.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_map_polyutil/google_map_polyutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  Position currentPosition;
  String currentAddress;
  Set<Marker> markers = {};
  PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Uint8List locImg, obstImg;

  Future<void> setImages() async {
    this.locImg = await this.getBytesFromAsset("assets/images/loc.png", 64);
    this.obstImg = await this.getBytesFromAsset("assets/images/dot.png", 24);
  }

  getAddress(Position position) async {
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

  getBytesFromAsset(String path, int width) async {
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
          ? BitmapDescriptor.fromBytes(this.obstImg)
          : BitmapDescriptor.fromBytes(this.locImg),
    );
    this.markers.add(marker);
  }

  addObstacle() async {
    Api api = Api();
    await api.addObstacle(
        this.currentPosition.latitude, this.currentPosition.longitude);
    await this.addMarker(this.currentPosition);
  }

  getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return position;
  }

  double coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  createPolylines(Position start, Position destination) async {
    NetworkHelper network = NetworkHelper(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: destination.latitude,
      endLng: destination.longitude,
    );

    try {
      Api api = Api();
      // getData() returns a json Decoded data
      var data = await network.getData();
      // We can reach to our desired JSON data manually as following
      LineString ls =
          LineString(data['features'][0]['geometry']['coordinates']);
      List<List<double>> dat = [];
      for (int i = 0; i < ls.lineString.length; i++) {
        dat.add([ls.lineString[i][1], ls.lineString[i][0]]);
        polylineCoordinates
            .add(LatLng(ls.lineString[i][1], ls.lineString[i][0]));
      }
      var obstacles = [];
      obstacles = await api.getAllObstacles();
      for (var obstacle in obstacles) {
        LatLng point = LatLng(obstacle['lat'], obstacle['lon']);
        if (await GoogleMapPolyUtil.isLocationOnEdge(
            point: point, polygon: polylineCoordinates)) {
          await this.addMarker(
              Position(latitude: point.latitude, longitude: point.longitude));
        }
      }
    } catch (e) {
      print(e);
    }
    PolylineId id = PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.green,
      points: polylineCoordinates,
      width: 3,
    );
    polylines[id] = polyline;
  }

  mapRoute(
      String _startAddress,
      String _destinationAddress,
      String _currentAddress,
      Position _currentPosition,
      GoogleMapController mapController) async {
    try {
      List<Location> startPlacemark = await locationFromAddress(_startAddress);
      List<Location> destinationPlacemark =
          await locationFromAddress(_destinationAddress);

      if (startPlacemark != null && destinationPlacemark != null) {
        // Use the retrieved coordinates of the current position,
        // instead of the address if the start position is user's
        // current position, as it results in better accuracy.
        Position startCoordinates = _startAddress == _currentAddress
            ? Position(
                latitude: _currentPosition.latitude,
                longitude: _currentPosition.longitude)
            : Position(
                latitude: startPlacemark[0].latitude,
                longitude: startPlacemark[0].longitude);
        Position destinationCoordinates = Position(
            latitude: destinationPlacemark[0].latitude,
            longitude: destinationPlacemark[0].longitude);

        // Adding the markers to the list
        this.addMarker(startCoordinates, false, "Start");
        this.addMarker(destinationCoordinates, false, "Destination");

        Position _northeastCoordinates;
        Position _southwestCoordinates;

        // Calculating to check that the position relative
        // to the frame, and pan & zoom the camera accordingly.
        double miny =
            (startCoordinates.latitude <= destinationCoordinates.latitude)
                ? startCoordinates.latitude
                : destinationCoordinates.latitude;
        double minx =
            (startCoordinates.longitude <= destinationCoordinates.longitude)
                ? startCoordinates.longitude
                : destinationCoordinates.longitude;
        double maxy =
            (startCoordinates.latitude <= destinationCoordinates.latitude)
                ? destinationCoordinates.latitude
                : startCoordinates.latitude;
        double maxx =
            (startCoordinates.longitude <= destinationCoordinates.longitude)
                ? destinationCoordinates.longitude
                : startCoordinates.longitude;

        _southwestCoordinates = Position(latitude: miny, longitude: minx);
        _northeastCoordinates = Position(latitude: maxy, longitude: maxx);

        mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              northeast: LatLng(
                _northeastCoordinates.latitude,
                _northeastCoordinates.longitude,
              ),
              southwest: LatLng(
                _southwestCoordinates.latitude,
                _southwestCoordinates.longitude,
              ),
            ),
            100.0,
          ),
        );
        await this.createPolylines(startCoordinates, destinationCoordinates);

        double totalDistance = 0.0;

        // Calculating the total distance by adding the distance
        // between small segments
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += this.coordinateDistance(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }

        return totalDistance;
      }
    } catch (e) {
      print(e);
      return -1;
    }
  }
}
