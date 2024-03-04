import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Listings extends StatefulWidget {
  const Listings({super.key});

  @override
  State<Listings> createState() => _ListingsState();
}

class _ListingsState extends State<Listings> {
  final Map<String, Marker> _markers = {};

  Future<void> _fetchAndSetMarkers() async {
    final therapists = await FirebaseFirestore.instance.collection('listings').get();
    setState(() {
      _markers.clear();
      for (final therapist in therapists.docs) {
        final geoPoint = therapist['location'] as GeoPoint;
        final marker = Marker(
          markerId: MarkerId(therapist['uid']),
          position: LatLng(geoPoint.latitude, geoPoint.longitude),
          infoWindow: InfoWindow(
            title: "${therapist['fname']} ${therapist['sname']}",
            snippet: therapist['disciplines'].join(', '),
            onTap: () {
              // Implement navigation to therapist's listing page
            },
          ),
        );
        _markers[therapist['uid']] = marker;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchAndSetMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(53.49358154992425, -6.175091204570396), // Default location
                zoom: 14,
              ),
              markers: _markers.values.toSet(),
            ),
          ),
          Expanded(
            flex: 3,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.requireData;

                return ListView.builder(
                  itemCount: data.size,
                  itemBuilder: (context, index) {
                    var therapist = data.docs[index];
                    return ListTile(
                      title: Text("${therapist['fname']} ${therapist['sname']}"),
                      subtitle: Text(therapist['disciplines'].join(', ')),
                      trailing: Icon(Icons.arrow_forward),
                      onTap: () {
                        // Handle the tap if you want to do something when a user taps on a listing
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}