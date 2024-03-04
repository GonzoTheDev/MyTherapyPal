import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math' as math;

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

  // Set to keep track of expanded listings' uids
  final Set<String> _expandedListings = <String>{};

  String? _selectedListingUid;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentLocation();
    await _fetchAndSetMarkers();
    //_setCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    LocationData locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _currentUserLocation = const LatLng(0, 0); 
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _currentUserLocation = const LatLng(0, 0); 
        return;
      }
    }

    locationData = await location.getLocation();
    _currentUserLocation = LatLng(locationData.latitude!, locationData.longitude!);
  }

  Future<void> _fetchAndSetMarkers() async {
    final therapists = await FirebaseFirestore.instance.collection('listings').get();
    final currentLocation = _currentUserLocation;
    if (currentLocation == null) {
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
            onTap: () {
              // TODO: Implement expanding the listing when the marker is tapped
            },
          ),
        );
        _markers[therapist['uid']] = marker;
      }
      _distances.addAll(tempDistances);
    });
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
    if (_mapController != null && currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            zoom: 12.0,
          ),
        ),
      );
    } else {
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

    // Center the map on the selected marker
    final newPosition = _markers[uid]?.position;
    if (newPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPosition, zoom: 14.0),
        ),
      );
    } else {
    }
  }

  void _updateMarkerIcon(String uid, BitmapDescriptor icon) {
    final marker = _markers[uid];
    if (marker != null) {
      setState(() {
        _markers[uid] = marker.copyWith(
          iconParam: icon,
        );
      });
    } else {
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


                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    var therapist = data[index];
                    var therapistId = therapist.get('uid') as String;
                    var distance = _distances[therapistId]!.toStringAsFixed(2);
                    var isExpanded = _expandedListings.contains(therapistId);

                    return ExpansionTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.location_on, size: 20.0),
                          Text("$distance km", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      title: Text("${therapist['fname'] ?? 'Unknown'} ${therapist['sname'] ?? 'Name'}"),
                      subtitle: Text(therapist['disciplines'].join(', ') ?? 'No disciplines'),
                      trailing: Icon(isExpanded ? Icons.arrow_drop_down : Icons.arrow_forward_ios),
                      onExpansionChanged: (bool expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedListings.add(therapistId);
                            _selectListing(therapistId);
                          } else {
                            _expandedListings.remove(therapistId);
                          }
                        });
                      },
                      initiallyExpanded: isExpanded,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Details: More details here", style: TextStyle(fontSize: 14)),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement send message functionality
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
