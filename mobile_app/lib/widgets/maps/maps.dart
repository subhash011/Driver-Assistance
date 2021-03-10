// @dart=2.10

import 'package:PotholeDetector/services/maps.dart';
import 'package:flutter/material.dart';
import 'package:PotholeDetector/widgets/maps/secrets.dart'; // Stores the Google Maps API Key
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mapbox_autocomplete/flutter_mapbox_autocomplete.dart'
    as FLAutoComplete;
import 'dart:math' show cos, sqrt, asin;

import 'network.dart';

class LineString {
  LineString(this.lineString);
  List<dynamic> lineString;
}

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  GoogleMapController mapController;
  MapService mapService = MapService();

  Position _currentPosition;
  String _currentAddress;

  final startAddressController = TextEditingController();
  final destinationAddressController = TextEditingController();

  final startAddressFocusNode = FocusNode();
  final desrinationAddressFocusNode = FocusNode();

  String _startAddress = '';
  String _destinationAddress = '';

  PolylinePoints polylinePoints;
  Map<PolylineId, Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _textField({
    TextEditingController controller,
    FocusNode focusNode,
    String label,
    String hint,
    double width,
    Icon prefixIcon,
    Widget suffixIcon,
    Function(String) locationCallback,
  }) {
    return Center(
      child: Container(
        width: width * 0.8,
        child: TextField(
          onChanged: (value) {
            locationCallback(value);
          },
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FLAutoComplete.MapBoxAutoCompleteWidget(
                  apiKey: Secrets.MAP_BOX_API_KEY,
                  hint: hint,
                  onSelect: (place) {
                    controller.text = place.placeName;
                  },
                  limit: 10,
                  country: "IN",
                ),
              ),
            );
          },
          controller: controller,
          focusNode: focusNode,
          decoration: new InputDecoration(
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
              borderSide: BorderSide(
                color: Colors.grey[400],
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
              borderSide: BorderSide(
                color: Colors.blue[300],
                width: 2,
              ),
            ),
            contentPadding: EdgeInsets.all(15),
            hintText: hint,
          ),
        ),
      ),
    );
  }

  // Method for retrieving the current location
  _getCurrentLocation() async {
    Position position = await mapService.getCurrentLocation();
    setState(() {
      _currentPosition = position;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
          ),
        ),
      );
    });
    String address = await mapService.getAddress(position);
    setState(() {
      _currentAddress = address;
      startAddressController.text = _currentAddress;
      _startAddress = _currentAddress;
    });
  }

  // Method for calculating the distance between two places
  Future<bool> _calculateDistance() async {
    try {
      // Retrieving placemarks from addresses
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
        mapService.addMarker(startCoordinates, false, "Start");
        mapService.addMarker(destinationCoordinates, false, "Destination");

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

        // Accommodate the two locations within the
        // camera view of the map
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

        await _createPolylines(startCoordinates, destinationCoordinates);

        double totalDistance = 0.0;

        // Calculating the total distance by adding the distance
        // between small segments
        for (int i = 0; i < polylineCoordinates.length - 1; i++) {
          totalDistance += _coordinateDistance(
            polylineCoordinates[i].latitude,
            polylineCoordinates[i].longitude,
            polylineCoordinates[i + 1].latitude,
            polylineCoordinates[i + 1].longitude,
          );
        }

        setState(() {});

        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  // Formula for calculating distance between two coordinates
  // https://stackoverflow.com/a/54138876/11910277
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  setPolyLines(List<LatLng> polyPoints, Set<Polyline> polyLines) {
    Polyline polyline = Polyline(
      polylineId: PolylineId("polyline"),
      color: Colors.lightBlue,
      points: polyPoints,
    );
    polyLines.add(polyline);
    setState(() {});
  }

  // Create the polylines for showing the route between two places
  _createPolylines(Position start, Position destination) async {
    NetworkHelper network = NetworkHelper(
      startLat: start.latitude,
      startLng: start.longitude,
      endLat: destination.latitude,
      endLng: destination.longitude,
    );
    final Set<Polyline> polyLines = {}; // For holding instance of Polyline

    try {
      // getData() returns a json Decoded data
      var data = await network.getData();
      // We can reach to our desired JSON data manually as following
      LineString ls =
          LineString(data['features'][0]['geometry']['coordinates']);

      for (int i = 0; i < ls.lineString.length; i++) {
        polylineCoordinates
            .add(LatLng(ls.lineString[i][1], ls.lineString[i][0]));
      }

      if (polylineCoordinates.length == ls.lineString.length) {
        setPolyLines(polylineCoordinates, polyLines);
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    return Container(
      height: height,
      width: width,
      child: Scaffold(
        key: _scaffoldKey,
        body: Stack(
          children: <Widget>[
            // Map View
            GoogleMap(
              markers: mapService.markers != null
                  ? Set<Marker>.from(mapService.markers)
                  : null,
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue[100], // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.add),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomIn(),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ClipOval(
                      child: Material(
                        color: Colors.blue[100], // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.remove),
                          ),
                          onTap: () {
                            mapController.animateCamera(
                              CameraUpdate.zoomOut(),
                            );
                          },
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Show the place input fields & button for
            // showing the route
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: FloatingActionButton(
                    child: Icon(Icons.search),
                    onPressed: () {
                      showModalBottomSheet(
                        isScrollControlled: true,
                        context: context,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBox(
                                height: 10.0,
                              ),
                              Center(
                                child: Text('Find route'),
                              ),
                              SizedBox(
                                height: 10.0,
                              ),
                              _textField(
                                  label: 'Start',
                                  hint: 'Choose starting point',
                                  prefixIcon: Icon(Icons.looks_one),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.my_location),
                                    onPressed: () {
                                      startAddressController.text =
                                          _currentAddress;
                                      _startAddress = _currentAddress;
                                    },
                                  ),
                                  controller: startAddressController,
                                  focusNode: startAddressFocusNode,
                                  width: width,
                                  locationCallback: (String value) async {
                                    setState(() {
                                      _startAddress = value;
                                    });
                                  }),
                              SizedBox(
                                height: 10,
                              ),
                              _textField(
                                  label: 'Destination',
                                  hint: 'Choose destination',
                                  prefixIcon: Icon(Icons.looks_two),
                                  controller: destinationAddressController,
                                  focusNode: desrinationAddressFocusNode,
                                  width: width,
                                  locationCallback: (String value) async {
                                    setState(() {
                                      _destinationAddress = value;
                                    });
                                  }),
                              SizedBox(height: 10),
                              Center(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (_startAddress == '' ||
                                        _destinationAddress == '') return null;
                                    startAddressFocusNode.unfocus();
                                    desrinationAddressFocusNode.unfocus();
                                    setState(() {
                                      if (mapService.markers.isNotEmpty)
                                        mapService.markers.clear();
                                      if (polylines.isNotEmpty)
                                        polylines.clear();
                                      if (polylineCoordinates.isNotEmpty)
                                        polylineCoordinates.clear();
                                    });

                                    try {
                                      var isCalculated =
                                          await _calculateDistance();
                                    } catch (e) {
                                      print(e);
                                    } finally {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  child: Container(
                                    child: Text(
                                      'Go',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom),
                              ),
                              SizedBox(
                                height: 10,
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Show current location button
            SafeArea(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                  child: ClipOval(
                    child: Material(
                      color: Colors.orange[100], // button color
                      child: InkWell(
                        splashColor: Colors.orange, // inkwell color
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(Icons.my_location),
                        ),
                        onTap: () async {
                          await _getCurrentLocation();
                          mapController.animateCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(
                                target: LatLng(
                                  _currentPosition.latitude,
                                  _currentPosition.longitude,
                                ),
                                zoom: 18.0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
