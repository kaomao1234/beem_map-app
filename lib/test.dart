import 'package:flutter/material.dart';
import 'package:flutter_polylines_moving_marker_demo/splash_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Splash(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};

  Set<Marker> markers = Set();

  LatLng loc1 = const LatLng(28.612898, 77.365930);

  int numDeltas = 40;
  int delay = 40;
  var i = 0;
  double? deltaLat;
  double? deltaLng;
  var position;

  late LatLng pos1;
  late LatLng pos2;

  @override
  void initState() {
    position = [loc1.latitude, loc1.longitude];
    pos1 = loc1;
    pos2 = loc1;
    addMarkers();
    super.initState();
  }

  addMarkers() async {
    markers.add(Marker(
        markerId: MarkerId(loc1.toString()),
        position: loc1,
        icon: BitmapDescriptor.defaultMarker));

    setState(() {});
  }

  animation(result) {
    i = 0;
    deltaLat = (result[0] - position[0]) / numDeltas;
    deltaLng = (result[1] - position[1]) / numDeltas;
    movingMarker();
  }

  movingMarker() {
    position[0] += deltaLat;
    position[1] += deltaLng;
    var latlng = LatLng(position[0], position[1]);

    markers = {
      Marker(
        markerId: const MarkerId("moving marker"),
        position: latlng,
        icon: BitmapDescriptor.defaultMarker,
      )
    };

    pos1 = pos2;
    pos2 = LatLng(position[0], position[1]);

    polylines.add(Polyline(
      polylineId: PolylineId(pos2.toString()),
      visible: true,
      width: 5,
//width of polyline
      points: [
        pos1,
        pos2,
      ],
      color: Colors.blue, //color of polyline
    ));

    setState(() {
//refresh UI
    });

    if (i != numDeltas) {
      i++;
      Future.delayed(Duration(milliseconds: delay), () {
        movingMarker();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            "Flutter Moving Marker Using Polylines",
          ),
          backgroundColor: Colors.red.shade300,
        ),
        floatingActionButton: SizedBox(
          height: MediaQuery.of(context).size.height * 0.3,
          width: MediaQuery.of(context).size.width * 0.175,
          child: FloatingActionButton(
            backgroundColor: Colors.red.shade300,
            child: const Center(
                child: Text(
              "Start\nMoving",
              textAlign: TextAlign.center,
            )),
            onPressed: () {
              var result = [28.6279, 77.3749];

              animation(result);
            },
          ),
        ),
        body: GoogleMap(
          zoomGesturesEnabled: true,
          initialCameraPosition: CameraPosition(
            target: loc1,
            zoom: 14.0,
          ),
          markers: markers,
          polylines: polylines,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            setState(() {
              mapController = controller;
            });
          },
        ));
  }
}
