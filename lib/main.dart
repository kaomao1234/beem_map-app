import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_maps/secrets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

// import 'dart:math' show cos, sqrt, asin;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Maps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapView(),
    );
  }
}

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  double _originLatitude = 16.7478645, _originLongitude = 100.1934934;
  double _destLatitude = 16.7426356, _destLongitude = 100.1946241;

  Map<MarkerId, Marker> markers = {};
  ValueNotifier<Map<PolylineId, Polyline>> polylines =
      ValueNotifier({});
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  String googleAPiKey = Secrets.API_KEY;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  late Position _currentPosition;


  Future<Position> fetchCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    log("$position");
    return position;
  }

  @override
  void initState() {
    super.initState();
  }

  _addMarker(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker =
        Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  _addPolyLine() {
    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 2,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType: JointType.round,
      geodesic: true,
    );
    Map<PolylineId, Polyline> temp = Map.from(polylines.value);
    temp[id] = polyline;
    polylines.value = temp;
  }

  _getPolyline(PointLatLng origin, PointLatLng destination) async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleAPiKey, origin, destination,
        travelMode: TravelMode.driving,
        optimizeWaypoints:
            true); // กำหนดให้เรียงลำดับจุดใหม่เพื่อให้ได้เส้นทางที่ใกล้ที่สุด
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {}
    _addPolyLine();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: FutureBuilder(
        future: fetchCurrentLocation(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final position = snapshot.data;
            final originalLatLng =
                LatLng(position!.latitude, position.longitude);
            final destLatLng =
                LatLng(position!.latitude + 0.002, position.longitude + 0.001);
            final originalPointLatLng =
                PointLatLng(position!.latitude, position.longitude);
            final destPointLatLng = PointLatLng(
                position!.latitude + 0.002, position.longitude + 0.001);
            _addMarker(
                originalLatLng, "origin", BitmapDescriptor.defaultMarker);
            _addMarker(
                destLatLng,
                "destination",
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue));
            _getPolyline(originalPointLatLng, destPointLatLng);
            return ValueListenableBuilder(
              valueListenable: polylines,
              builder: (context, value, child) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: originalLatLng,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  tiltGesturesEnabled: true,
                  compassEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  markers: Set<Marker>.of(markers.values),
                  polylines: Set<Polyline>.of(value.values),
                  // mapType: MapType.terrain,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                );
              },
            );
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      )),
    );
  }
}
