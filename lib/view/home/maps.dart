import 'dart:convert';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';

class GoogleMaps extends StatefulWidget {
  final Function(String) onLocationFetched;
  final String destinationAddress;
  final FlutterTts flutterTts; // Add FlutterTts as a parameter

  const GoogleMaps({
    super.key,
    required this.onLocationFetched,
    required this.destinationAddress,
    required this.flutterTts, // Initialize FlutterTts
  });

  @override
  State<GoogleMaps> createState() => MapSampleState();
}

class MapSampleState extends State<GoogleMaps> {
  GoogleMapController? mapController;

  final CameraPosition _initialPosition = const CameraPosition(
    target:
        LatLng(double.infinity, double.infinity), // Example default location
    zoom: 20,
  );

  Marker? _currentLocationMarker;
  Marker? _destinationMarker;
  Polyline? _routePolyline;
  BitmapDescriptor? _customIcon;
  bool _hasSpokenDestination = false;
  StreamSubscription<Position>? _positionStreamSubscription; // Add this

  @override
  void initState() {
    super.initState();
    getIcon();
    _startTracking();
    _location(); // Fetch current location and add markers
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel(); // Dispose of the stream
    super.dispose();
  }

  @override
  void didUpdateWidget(GoogleMaps oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationAddress != oldWidget.destinationAddress) {
      _hasSpokenDestination = false; // Reset the flag
      _setDestinationAndPolyline(
          widget.destinationAddress,
          _currentLocationMarker?.position ??
              const LatLng(double.infinity, double.infinity));
    }
  }

  Future<Uint8List?> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    var codec = await instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ImageByteFormat.png))
        ?.buffer
        .asUint8List();
  }

  Future<void> getIcon() async {
    final Uint8List? iconUint8List =
        await _getBytesFromAsset('assets/images/man.png', 100);
    // ignore: deprecated_member_use
    _customIcon = BitmapDescriptor.fromBytes(iconUint8List!);
  }

  Future<void> _location() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    String address = await _getAddressFromLatLng(
      position.latitude,
      position.longitude,
    );

    widget.onLocationFetched(address);
    _addCurrentLocationMarker(position.latitude, position.longitude);
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      _addCurrentLocationMarker(position.latitude, position.longitude);
    });
  }

  void _stopTracking() {
    _positionStreamSubscription?.cancel(); // Stop the stream
  }

  void _addCurrentLocationMarker(double lat, double lng) {
    LatLng currentPosition = LatLng(lat, lng);
    setState(() {
      _currentLocationMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        position: currentPosition,
        icon: _customIcon!,
      );
    });

    // Update polyline if destination is set
    if (widget.destinationAddress.isNotEmpty) {
      _setDestinationAndPolyline(widget.destinationAddress, currentPosition);
    }
    if (!_hasSpokenDestination) {
      // Animate camera to the current position
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition,
            zoom: 15.0,
          ),
        ),
      );
    }
  }

  Future<void> _setDestinationAndPolyline(
      String address, LatLng currentPosition) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isEmpty) {
        // Speak "Address not found"
        await widget.flutterTts.speak("Address not found");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address not found")),
        );
        return; // Exit the function early
      }

      LatLng destinationPosition =
          LatLng(locations.first.latitude, locations.first.longitude);

      // Google Directions API URL
      String googleApiKey = 'AIzaSyDfaF1ZpHjao2o27rN2Fx_zOV-H5x-u1-M';
      String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&mode=walking&key=$googleApiKey';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          String encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];
          List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);

          setState(() {
            _destinationMarker = Marker(
              markerId: const MarkerId('destination'),
              position: destinationPosition,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            );

            _routePolyline = Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            );
          });

          // Adjust camera to include both markers
          mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(
                  min(currentPosition.latitude, destinationPosition.latitude),
                  min(currentPosition.longitude, destinationPosition.longitude),
                ),
                northeast: LatLng(
                  max(currentPosition.latitude, destinationPosition.latitude),
                  max(currentPosition.longitude, destinationPosition.longitude),
                ),
              ),
              50.0,
            ),
          );
          if (!_hasSpokenDestination) {
            // Speak the destination address
            await widget.flutterTts.speak("Navigating to $address");
            // // Add a delay to allow the speech to complete
            _hasSpokenDestination = true;
            await Future.delayed(const Duration(seconds: 2));
            // // Navigate to the next screen
            Navigator.pushNamed(context, RoutesNames.cameraView, arguments: [
              widget.destinationAddress,
              currentPosition,
              destinationPosition
            ]).then((_) {
              // Resume tracking when returning to the maps screen
              _startTracking();
            });
            _stopTracking(); // Stop tracking when navigating to the camera screen
          }
        } else {
          await widget.flutterTts
              .speak("No routes found for the given address");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("No routes found for the given address")),
          );
        }
      } else {
        await widget.flutterTts.speak("Failed to fetch directions");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text("Failed to fetch directions: ${response.statusCode}")),
        );
      }
    } catch (e) {
      await widget.flutterTts.speak("Error setting destination");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error setting destination: $e")),
      );
    }
  }

  List<LatLng> _decodePolyline(String encodedPolyline) {
    List<LatLng> polyline = [];
    int index = 0, len = encodedPolyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encodedPolyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  Future<String> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      Placemark place = placemarks.first;
      return "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
    } catch (e) {
      return "Unable to fetch address";
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: _initialPosition,
        markers: {
          if (_currentLocationMarker != null) _currentLocationMarker!,
          if (_destinationMarker != null) _destinationMarker!,
        },
        polylines: {
          if (_routePolyline != null) _routePolyline!,
        },
        myLocationEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
          if (widget.destinationAddress.isNotEmpty) {
            _setDestinationAndPolyline(
                widget.destinationAddress,
                _currentLocationMarker?.position ??
                    const LatLng(double.infinity, double.infinity));
          }
        },
      ),
    );
  }
}
