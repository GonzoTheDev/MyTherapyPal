import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {

  @override
  void initState() {
    super.initState();
    _fetchUserFirstName();
  }

  bool showTick = false; 

  // Define the text controllers for the note title and text
  final TextEditingController _noteTitleController = TextEditingController();
  final TextEditingController _noteTextController = TextEditingController();
  
  final uid = FirebaseAuth.instance.currentUser?.uid;
  String userFirstName = 'User';
  // Define the list of emojis and their associated feelings
  final List<Map<String, dynamic>> moods = [
    {'emoji': '😁', 'mood': 'Very Happy'},
    {'emoji': '🙂', 'mood': 'Happy'},
    {'emoji': '😐', 'mood': 'Indifferent'},
    {'emoji': '🙁', 'mood': 'Sad'},
    {'emoji': '😢', 'mood': 'Very Sad'},
  ];

  // Helper function to get the greeting based on the time of day
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<void> _fetchUserFirstName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        final documentSnapshot = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
        final fname = documentSnapshot.data()?['fname'] as String? ?? 'User';
        setState(() {
          userFirstName = fname;
        });
      } catch (e) {
        print("Error fetching user first name: $e");
      }
    }
  }

  // Function to add a mood to Firebase
  Future<void> addMoodToFirebase(String emoji) async {
    if (uid == null) return; 
    final collection = FirebaseFirestore.instance.collection('moods');
    final timestamp = Timestamp.now();
    await collection.add({
      'uid': uid,
      'emoji': emoji,
      'timestamp': timestamp,
    });
  }

  // Function to display a dialog for adding a note
  Future<void> _showAddNoteDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a note'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _noteTitleController,
                  decoration: InputDecoration(
                    hintText: "Title",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteTextController,
                  decoration: InputDecoration(
                    hintText: "Your note",
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  keyboardType: TextInputType.multiline,
                  minLines: 2,
                  maxLines: 10,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _noteTitleController.clear();
                _noteTextController.clear();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () async {
                await _addNoteToFirebase(_noteTitleController.text, _noteTextController.text);
                Navigator.of(context).pop();
                _noteTitleController.clear();
                _noteTextController.clear();
              },
            ),
          ],
        );
      },
    );
  }

  // Function to add a note to Firebase
  Future<void> _addNoteToFirebase(String title, String text) async {
  
    // Ensure the user is logged in
    if (uid == null) return; 
  
    final collection = FirebaseFirestore.instance.collection('notes');
    final timestamp = Timestamp.now();
    
    await collection.add({
      'uid': uid,
      'title': title,
      'text': text,
      'timestamp': timestamp,
    });
  }

  Widget _buildNotesTimeline() {
    if (uid == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notes')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true) 
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print("Error loading notes: ${snapshot.error}");
          return const Text("Error loading notes...");
        }
        if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "You haven't added any notes yet. Tap 'Add a note' to get started!",
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          );
        } else if (snapshot.hasData) {
          // Group the notes by month and year
          final notesGroupedByMonth = _groupNotesByMonth(snapshot.data!.docs);
          return ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: notesGroupedByMonth.entries.map((monthEntry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        monthEntry.key,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ...monthEntry.value.entries.map((dayEntry) {
                    List<Widget> dayNotes = [];
                    for (int i = 0; i < dayEntry.value.length; i++) {
                      var note = dayEntry.value[i];
                      DateTime date = (note['timestamp'] as Timestamp).toDate();
                      if (i == 0) {
                        // First note of the day, show date
                        dayNotes.add(ListTile(
                          leading: Column(
                            children: [
                              // Show day of the week and day of the month
                              Text(DateFormat('E').format(date), style: const TextStyle(fontSize: 12)), 
                              Text(DateFormat('d').format(date), style: const TextStyle(fontSize: 18)), 
                            ],
                          ),
                          title: Text(note['title']),
                          subtitle: Text(note['text']),
                        ));
                      } else {
                        // Subsequent note, show line
                        dayNotes.add(ListTile(
                          leading: const SizedBox(
                            width: 20,
                            child: VerticalDivider(thickness: 2, color: Colors.grey),
                          ),
                          title: Text(note['title']),
                          subtitle: Text(note['text']),
                        ));
                      }
                    }
                    return Column(children: dayNotes);
                  }),
                ],
              );
            }).toList(),
          );
        } else {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }


  Map<String, Map<String, List<Map<String, dynamic>>>> _groupNotesByMonth(List<QueryDocumentSnapshot> docs) {
    Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var doc in docs) {
      final note = doc.data() as Map<String, dynamic>;
      DateTime date = (note['timestamp'] as Timestamp).toDate();
      String monthYearKey = DateFormat('MMMM y').format(date);
      String dayKey = DateFormat('d').format(date);

      grouped.putIfAbsent(monthYearKey, () => {});
      var monthGroup = grouped[monthYearKey]!;
      monthGroup.putIfAbsent(dayKey, () => []);
      monthGroup[dayKey]!.add(note);
    }
    return grouped;
  }



    @override
    Widget build(BuildContext context) {
      double maxWidth = MediaQuery.of(context).size.width > 414 ? 414 : MediaQuery.of(context).size.width;
      var greeting = _getGreeting();
      return Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(
                height: 20.0,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('How are you feeling?', style: Theme.of(context).textTheme.titleLarge),
              ),
              Visibility(
                visible: !showTick, 
                replacement: const Center(
                  child: Icon(Icons.check_circle, color: Colors.green, size: 60), 
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: moods.map((mood) => MouseRegion(
                    cursor: SystemMouseCursors.click, 
                    child: GestureDetector(
                      onTap: () {
                        addMoodToFirebase(mood['emoji']);
                        setState(() => showTick = true);
                        Timer(const Duration(seconds: 1), () => setState(() => showTick = false)); 
                      },
                      child: Text(mood['emoji'], style: const TextStyle(fontSize: 24)),
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(
                height: 40.0,
              ),
              const Divider(
                        color: Colors.grey,
                        thickness: 1,
                        indent: 60,
                        endIndent: 60,
                      ),
              const SizedBox(
                height: 40.0,
              ),
              Text('$greeting, $userFirstName!', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(
                height: 20.0,
              ),
              Container(
                constraints: BoxConstraints(maxWidth: maxWidth / 2),
                child: 
              SizedBox(
                width: double.infinity/2,
                height: 50.0,
                child: ElevatedButton(
                  onPressed: _showAddNoteDialog,
                  style: ButtonStyle(
                    minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 36)),
                  ),
                  child: const Text(
                    'Add a note',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              ),
              const SizedBox(
                height: 60.0,
              ),
              _buildNotesTimeline(),
            ],
          ),
        ),
      );
    }
  }
