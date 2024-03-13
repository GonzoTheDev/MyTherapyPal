import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:my_therapy_pal/screens/chat_screen.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:my_therapy_pal/services/encryption/AES/encryption_service.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa.dart';
import 'package:my_therapy_pal/services/generate_chat.dart';

class Listings extends StatefulWidget {
  const Listings({super.key});

  @override
  State<Listings> createState() => _ListingsState();
}

class _ListingsState extends State<Listings> {
  Map<String, Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng? _currentUserLocation;
  final Map<String, double> _distances = {};
  final ScrollController _scrollController = ScrollController();
  final currentUid = FirebaseAuth.instance.currentUser!.uid;

  // Create a new instance of the Firebase Firestore
  var db = FirebaseFirestore.instance;

  // Create a new instance of the AES encryption service
  final aesKeyEncryptionService = AESKeyEncryptionService();

  // Create a new instance of the RSA encryption
  final rsaEncryption = RSAEncryption();

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


    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        ('Service not enabled, defaulting to LatLng(0, 0)');
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        ('Permission not granted, defaulting to LatLng(0, 0)');
        return;
      }
    }

    locationData = await location.getLocation();
    if (locationData.latitude == null || locationData.longitude == null) {
      ('Location data is null, defaulting to LatLng(0, 0)');
      _currentUserLocation = const LatLng(0, 0);
    } else {
      setState(() {
      _currentUserLocation = LatLng(locationData.latitude!, locationData.longitude!);
      _updateCameraPosition(_currentUserLocation!);
      });
    }
  }

  void _updateCameraPosition(LatLng position) {
  if (_mapController != null) {
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 11.0),
      ),
    );
  } else {
    print('Map controller is not initialized.');
  }
}

  Future<void> _fetchAndSetMarkers() async {
    try {
      final therapists = await FirebaseFirestore.instance.collection('listings').where('active', isEqualTo: true).where('approved', isEqualTo: true).get();
      final currentLocation = _currentUserLocation;

      // New map for updated markers
      Map<String, Marker> updatedMarkers = {};
      // Retain the user's location marker if it exists
      if (_markers.containsKey("userLocation")) {
        updatedMarkers["userLocation"] = _markers["userLocation"]!;
      }

      Map<String, double> tempDistances = {};
      for (final therapist in therapists.docs) {
        final geoPoint = therapist['location'] as GeoPoint;
        final therapistLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
        final distance = _calculateDistance(currentLocation!, therapistLocation);
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
        updatedMarkers[therapist['uid']] = marker;
      }

      setState(() {
        _markers = updatedMarkers;
        _distances.addAll(tempDistances);
      });
      print('Markers and distances updated');
    } catch (e) {
      print('Error fetching and setting markers: $e');
    }
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
          CameraPosition(target: newPosition, zoom: 11.0),
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

  Future<void> _startChat(String tuid) async {
    String firstUid = currentUid;
    String secondUid = tuid;

    // Get the first user's public RSA key from Firestore
    final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(firstUid).get();
    String firstUserRSAPubKey = userProfileDoc['publicRSAKey'];

    // Get the second user's public RSA key from Firestore
    DocumentSnapshot userDoc = await db.collection("profiles").doc(secondUid).get();
    String secondUserRSAPubKey = userDoc.get("publicRSAKey");

    // Generate an AES key for the chat room
    final aesKey = aesKeyEncryptionService.generateAESKey(16);

    // Encrypt the AES key with the current user's public RSA key
    final firstUserEncryptedAESKey = rsaEncryption.encrypt(
      key: firstUserRSAPubKey,
      message: aesKey.toString(),
    );

    // Encrypt the AES key with the second user's public RSA key
    final secondUserEncryptedAESKey = rsaEncryption.encrypt(
      key: secondUserRSAPubKey,
      message: aesKey.toString(),
    );

    // Generate a new chat
    String chatIdValue = await GenerateChat(
      aesKey: aesKey,
      encryptedAESKey: firstUserEncryptedAESKey,
      uid: firstUid,
    ).generateUserChat(secondUid, secondUserEncryptedAESKey);

    // If the chat is successfully created, navigate to the chat list
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatID: chatIdValue),
        ),
      );
    }
  }

  

  @override
  Widget build(BuildContext context) {
      final currentLocation = _currentUserLocation;
      final currentUserLocation = currentLocation != null
          ? LatLng(currentLocation.latitude, currentLocation.longitude)
          : const LatLng(0, 0);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              myLocationEnabled: true, 
              myLocationButtonEnabled: true,
              initialCameraPosition: CameraPosition(
                target: currentUserLocation,
                zoom: 11,
              ),
              markers: _markers.values.toSet(),
            ),
          ),
          Expanded(
            flex: 3,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').where('active', isEqualTo: true).where('approved', isEqualTo: true).snapshots(),
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
                    var distance = _distances[therapistId]?.toStringAsFixed(2) ?? 'N/A';
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
                                          Text('€${therapist['ratesFrom']}-${therapist['ratesTo']}', style: const TextStyle(fontSize: 14))
                                        ]),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _startChat(therapistId);
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
