import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class Listings extends StatefulWidget {
  const Listings({super.key});

  @override
  State<Listings> createState() => _ListingsState();
}

class _ListingsState extends State<Listings> {
  final Map<String, Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng? _currentUserLocation;
  final Map<String, double> _distances = {};
  ScrollController _scrollController = ScrollController();

  // Variables to keep track of selected and expanded listings' uids
  String? _expandedListingUid;
  String? _selectedListingUid;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentLocation();
    await _fetchAndSetMarkers();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    // Create a custom marker icon for the user's current location
    final markerIcon = await _createMarkerIconFromMaterialIcon(Icons.my_location, Colors.blue, 100);


    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        ('Service not enabled, defaulting to LatLng(0, 0)');
        _currentUserLocation = const LatLng(0, 0); 
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        ('Permission not granted, defaulting to LatLng(0, 0)');
        _currentUserLocation = const LatLng(0, 0); 
        return;
      }
    }

    locationData = await location.getLocation();
    if (locationData.latitude == null || locationData.longitude == null) {
      ('Location data is null, defaulting to LatLng(0, 0)');
      _currentUserLocation = const LatLng(0, 0);
    } else {
      _currentUserLocation = LatLng(locationData.latitude!, locationData.longitude!);
      
      // Create a marker for the user's current location
    final marker = Marker(
      markerId: const MarkerId("userLocation"),
      position: _currentUserLocation!,
      infoWindow: const InfoWindow(title: "Your Location"),
      icon: markerIcon, 
    );

    setState(() {
      // Add the marker to the map
      _markers["userLocation"] = marker;
    });
    }
  }

  Future<void> _fetchAndSetMarkers() async {
    try {
      final therapists = await FirebaseFirestore.instance.collection('listings').get();
      final currentLocation = _currentUserLocation;
      if (currentLocation == null) {
        ('Current location is null, aborting fetchAndSetMarkers');
        return; 
      }

      Map<String, double> tempDistances = {};
      setState(() {
        _markers.clear();
        for (final therapist in therapists.docs) {
          final geoPoint = therapist['location'] as GeoPoint;
          final therapistLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
          final distance = _calculateDistance(currentLocation, therapistLocation);
          tempDistances[therapist['uid']] = distance;

          final marker = Marker(
            markerId: MarkerId(therapist['uid']),
            position: therapistLocation,
            infoWindow: InfoWindow(
              title: "${therapist['fname']} ${therapist['sname']}",
              snippet: therapist['disciplines'].join(', '),
            ),
            onTap: () {
              _selectListing(therapist['uid']);
            },
          );
          _markers[therapist['uid']] = marker;
        }
        _distances.addAll(tempDistances);
      });
      ('Markers and distances updated');
    } catch (e) {
      ('Error fetching and setting markers: $e');
    }
  }

  // Convert the my_location icon into a BitmapDescriptor
  Future<BitmapDescriptor> _createMarkerIconFromMaterialIcon(IconData iconData, Color color, int size) async {

    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final iconStr = String.fromCharCode(iconData.codePoint);
    textPainter.text = TextSpan(text: iconStr, style: TextStyle(fontSize: size.toDouble(), fontFamily: iconData.fontFamily, color: color));
    textPainter.layout();
    textPainter.paint(canvas, Offset.zero);
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  double _calculateDistance(LatLng start, LatLng end) {
    var earthRadiusKm = 6371;
    var dLat = _degreesToRadians(end.latitude - start.latitude);
    var dLon = _degreesToRadians(end.longitude - start.longitude);
    var lat1 = _degreesToRadians(start.latitude);
    var lat2 = _degreesToRadians(end.latitude);

    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLon / 2) * math.sin(dLon / 2) * math.cos(lat1) * math.cos(lat2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    var distance = earthRadiusKm * c;
    return distance;
  }

  double _degreesToRadians(degrees) {
    return degrees * math.pi / 180;
  }

  void _setCurrentLocation() async {
    final currentLocation = _currentUserLocation;
    if (_mapController == null) {
      ('Map controller is null, cannot set current location');
    } else if (currentLocation == null) {
      ('Current location is null, cannot set current location');
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 12.0,
          ),
        ),
      );
      ('Camera updated to current location');
    }
  }

  void _selectListing(String uid) {
    // Check if there's a previously selected listing and revert its icon
    if (_selectedListingUid != null && _selectedListingUid != uid) {
      final oldMarker = _markers[_selectedListingUid!];
      if (oldMarker != null) {
        _updateMarkerIcon(_selectedListingUid!, BitmapDescriptor.defaultMarker);
      }
    }

    // Update the selected listing's marker icon
    _updateMarkerIcon(uid, BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue));

    // Track the currently selected listing
    _selectedListingUid = uid;

    // Set the expanded listing UID to the selected listing
    setState(() {
      _expandedListingUid = uid;
    });

    // Find the index of the listing in the data list
    WidgetsBinding.instance.addPostFrameCallback((_) {

    if (_scrollController.hasClients) {
      FirebaseFirestore.instance.collection('listings').get().then((snapshot) {
        var docs = snapshot.docs;
        var index = docs.indexWhere((doc) => doc['uid'] == uid);
        if (index != -1) {
          double scrollPosition = index * 80.0;
          _scrollController.animateTo(
            scrollPosition,
            duration: const Duration(seconds: 1),
            curve: Curves.easeOut,
          );
        }
      });
    }
  });

    // Center the map on the selected marker
    final newPosition = _markers[uid]?.position;
    if (newPosition == null) {
      ('New position is null, cannot select listing');
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPosition, zoom: 14.0),
        ),
      );
      ('Camera updated to selected listing position');
    }
  }

  void _updateMarkerIcon(String uid, BitmapDescriptor icon) {
    final marker = _markers[uid];
    if (marker == null) {
      ('Marker for uid $uid is null, cannot update icon');
    } else {
      setState(() {
        _markers[uid] = marker.copyWith(
          iconParam: icon,
        );
      });
      ('Marker icon updated for uid $uid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _setCurrentLocation();
              },
              initialCameraPosition: const CameraPosition(
                target: LatLng(53.34564797276651, -6.267732624686331), 
                zoom: 10,
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
                  ('Snapshot has error: ${snapshot.error}');
                  return const Text('Something went wrong');
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var data = snapshot.requireData.docs;

                // Sort listings by distance
                data.sort((a, b) {
                  final distanceA = _distances[a['uid']];
                  final distanceB = _distances[b['uid']];
                  if (distanceA == null && distanceB == null) {
                    return 0;
                  } else if (distanceA == null) {
                    return 1;
                  } else if (distanceB == null) {
                    return -1;
                  } else {
                    return distanceA.compareTo(distanceB);
                  }
                });

                ('Listings sorted and ready to display');

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    var therapist = data[index];
                    var therapistId = therapist.get('uid') as String;
                    var distance = _distances[therapistId]?.toStringAsFixed(2) ?? 'Unknown distance';
                    var isExpanded = _expandedListingUid == therapistId;

                    return ExpansionTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.location_on, size: 20.0, color: Color.fromARGB(255, 234, 68, 53),),
                          Text("$distance km", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      title: Text("${therapist['fname'] ?? 'Unknown'} ${therapist['sname'] ?? 'Name'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      subtitle: Text(therapist['disciplines'].join(', ') ?? 'No disciplines'),
                      trailing: Icon(isExpanded ? Icons.arrow_drop_down : Icons.arrow_forward_ios),
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedListingUid = therapistId;
                            _selectListing(therapistId);
                          } else if (_expandedListingUid == therapistId) {
                            _expandedListingUid = null;
                          }
                        });
                        ('Expansion changed for $therapistId, expanded: $expanded');
                      },
                      initiallyExpanded: isExpanded,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.start, 
                                children: [
                                  Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0), 
                                        child: therapist['pic_url'] != null
                                            ? Image.network(therapist['pic_url'], width: 100, height: 100)
                                            : const Icon(Icons.account_circle, size: 100),
                                      ),
                                    ],
                                  ),
                                  // Expanded Column for displaying phone number, address, and rates
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          const Text('Phone: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          Text('${therapist['phone']}', style: const TextStyle(fontSize: 14))
                                        ]),
                                        const SizedBox(height: 5), 
                                        const Text('Address: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                        Text('${therapist['address'].replaceAll('\\n', '\n')}', style: const TextStyle(fontSize: 14)),
                                        const SizedBox(height: 5), 
                                        Row(children: [
                                          const Text('Rates: ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          Text('${therapist['rates']}', style: const TextStyle(fontSize: 14))
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // Implement send message functionality
                                  ('Send message button pressed for $therapistId');
                                },
                                child: const Text('Send Message'),
                              ),
                            ],
                          ),
                        ),
                      ],
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
