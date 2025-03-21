import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class FloatingMap extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destination;
  final Function(String) onTurnCallback;

  const FloatingMap({
    super.key,
    required this.currentLocation,
    required this.destination,
    required this.onTurnCallback,
  });

  @override
  State<FloatingMap> createState() => _FloatingMapState();
}

class _FloatingMapState extends State<FloatingMap> {
  GoogleMapController? _mapController;
  Polyline? _routePolyline;
  LatLng? currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    currentLocation = widget.currentLocation;
    _fetchRouteAndSetPolyline();
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      final LatLng newLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = newLocation; // Update current location
      });

      Marker(
        markerId: const MarkerId('currentLocation'),
        position: newLocation,
        icon: BitmapDescriptor.defaultMarker,
      );
      // Keep the current location in view
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(newLocation),
      );
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchRouteAndSetPolyline() async {
    const String googleApiKey = 'AIzaSyDfaF1ZpHjao2o27rN2Fx_zOV-H5x-u1-M';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${currentLocation?.latitude},${currentLocation?.longitude}&destination=${widget.destination.latitude},${widget.destination.longitude}&mode=walking&key=$googleApiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final String encodedPolyline =
            data['routes'][0]['overview_polyline']['points'];
        final List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);

        setState(() {
          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            points: polylinePoints,
            color: Colors.blue,
            width: 5,
          );
        });

        _monitorTurns(polylinePoints);
      }
    }
  }

  void _monitorTurns(List<LatLng> polylinePoints) {
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final LatLng userLocation = LatLng(position.latitude, position.longitude);

      // Find the nearest point on the polyline
      double minDistance = double.infinity;
      int nearestIndex = 0;
      for (int i = 0; i < polylinePoints.length; i++) {
        final double distance =
            _calculateDistance(userLocation, polylinePoints[i]);
        if (distance < minDistance) {
          minDistance = distance;
          nearestIndex = i;
        }
      }

      // Check if the user is approaching a turn
      if (nearestIndex < polylinePoints.length - 1) {
        final LatLng nextPoint = polylinePoints[nearestIndex + 1];
        final double bearing = _calculateBearing(
          polylinePoints[nearestIndex],
          nextPoint,
        );

        // Provide turn instructions based on bearing
        if (bearing >= 45 && bearing < 135) {
          widget.onTurnCallback("Turn right in 100 meters");
        } else if (bearing >= 225 && bearing < 315) {
          widget.onTurnCallback("Turn left in 100 meters");
        } else {
          widget.onTurnCallback("Continue straight");
        }
      }
    });
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // in meters
    final double lat1 = point1.latitude * (pi / 180);
    final double lon1 = point1.longitude * (pi / 180);
    final double lat2 = point2.latitude * (pi / 180);
    final double lon2 = point2.longitude * (pi / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final double lat1 = start.latitude * (pi / 180);
    final double lon1 = start.longitude * (pi / 180);
    final double lat2 = end.latitude * (pi / 180);
    final double lon2 = end.longitude * (pi / 180);

    final double y = sin(lon2 - lon1) * cos(lat2);
    final double x =
        cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(lon2 - lon1);
    final double bearing = atan2(y, x) * (180 / pi);

    return (bearing + 360) % 360; // Normalize to 0-360 degrees
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.currentLocation,
            zoom: 15,
          ),
          polylines: {
            if (_routePolyline != null) _routePolyline!,
          },
          markers: {
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: widget.currentLocation,
              icon: BitmapDescriptor.defaultMarker,
            ),
            Marker(
              markerId: const MarkerId('destination'),
              position: widget.destination,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
            ),
          },
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }
}
