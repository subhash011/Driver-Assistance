// @dart=2.10

import 'package:PotholeDetector/services/maps.dart';
import 'package:PotholeDetector/services/obstacle.dart';
import 'package:PotholeDetector/services/voice.dart';
import 'package:flutter/material.dart';
import 'package:PotholeDetector/widgets/maps/secrets.dart'; // Stores the Google Maps API Key
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_mapbox_autocomplete/flutter_mapbox_autocomplete.dart'
    as FLAutoComplete;

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
    String address = await mapService.getAddress(position);
    setState(() {
      _currentPosition = position;
      _currentAddress = address;
      startAddressController.text = _currentAddress;
      _startAddress = _currentAddress;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18.0,
          ),
        ),
      );
    });
  }

  @override
  void initState() {
    Obstacles obs = Obstacles();
    Voice voice = Voice();
    super.initState();
    obs.signal.stream.listen((event) async {
      if (event >= 1) {
        mapService.addObstacle();
        setState(() {});
      }
    });
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
              polylines: Set<Polyline>.of(mapService.polylines.values),
              onMapCreated: (GoogleMapController controller) async {
                mapController = controller;
                await _getCurrentLocation();
              },
            ),
            // Show zoom buttons
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    ClipOval(
                      child: Material(
                        color: Colors.blue[100], // button color
                        child: InkWell(
                          splashColor: Colors.blue, // inkwell color
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: Icon(Icons.zoom_in),
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
                            child: Icon(Icons.zoom_out),
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
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                  child: ElevatedButton(
                    child: Text("Add Obstacle here"),
                    onPressed: () {
                      mapService.addObstacle();
                      setState(() {});
                    },
                  ),
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
                                      if (mapService.polylines.isNotEmpty)
                                        mapService.polylines.clear();
                                      if (mapService
                                          .polylineCoordinates.isNotEmpty)
                                        mapService.polylineCoordinates.clear();
                                    });
                                    double totalDistance = -1;
                                    try {
                                      totalDistance = await mapService.mapRoute(
                                          _startAddress,
                                          _destinationAddress,
                                          _currentAddress,
                                          _currentPosition,
                                          mapController);
                                    } catch (e) {
                                      print(e);
                                    } finally {
                                      setState(() {});
                                      Navigator.of(context).pop();
                                      final snackBar = SnackBar(
                                        content: Text(
                                          totalDistance >= 0
                                              ? totalDistance
                                                      .toStringAsFixed(2) +
                                                  " km"
                                              : "There was some error!",
                                          textAlign: TextAlign.center,
                                        ),
                                        action: SnackBarAction(
                                          label: 'Ok',
                                          onPressed: () {
                                            // Some code to undo the change.
                                          },
                                        ),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
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
