import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

class PropsLatLng {
  LatLng origin, dest;
  PropsLatLng(this.origin, this.dest);

  setOrigin(double lat, double long) {
    origin = LatLng(lat, long);
  }

  setDest(double lat, double long) {
    dest = LatLng(lat, long);
  }

  PointLatLng toPointOrigin() {
    return PointLatLng(origin.latitude, origin.longitude);
  }

  PointLatLng toPointDest() {
    return PointLatLng(dest.latitude, dest.longitude);
  }

  copy() {
    return PropsLatLng(origin, dest);
  }
}

class _MapViewState extends State<MapView> {
  Map<MarkerId, Marker> markers = {};
  PropsLatLng propsLatLng = PropsLatLng(LatLng(0, 0), LatLng(0, 0));
  ValueNotifier<Map<PolylineId, Polyline>> polylines = ValueNotifier({});
  List<LatLng> polylineCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints();

  String googleAPiKey = Secrets.API_KEY;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  Future<Position> fetchCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    // log("$position");
    return position;
  }

  @override
  void initState() {
    super.initState();
  }

  void _updateMarkersAndPolylines() {
    propsLatLng.setDest(propsLatLng.dest.latitude + 0.0001,
        propsLatLng.dest.longitude + 0.0001);
    _addMarker(propsLatLng.origin, "origin", BitmapDescriptor.defaultMarker);
    _addMarker(propsLatLng.dest, "destination",
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));
    _getPolyline(propsLatLng.toPointOrigin(), propsLatLng.toPointDest());
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
    polylines.value[id] = polyline;
    polylines.notifyListeners();
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
    }
    polylines.notifyListeners();
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
            log(snapshot.data.toString());
            propsLatLng.setOrigin(
                snapshot.data!.latitude, snapshot.data!.longitude);
            propsLatLng.setDest(snapshot.data!.latitude + 0.001,
                snapshot.data!.longitude + 0.001);
              Timer.periodic(Duration(seconds: 3), (timer) {
            markers.clear();
            polylineCoordinates.clear();
            polylines.value.clear();
            _updateMarkersAndPolylines();
          });
            return ValueListenableBuilder(
              valueListenable: polylines,
              builder: (context, value, child) {
                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: propsLatLng.origin,
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
          }
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    ));
  }
}
