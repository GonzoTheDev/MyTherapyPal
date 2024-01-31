import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:my_therapy_pal/screens/chat_list_screen.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:my_therapy_pal/widgets/nav_drawer.dart';
import '../services/auth_service.dart';
import 'package:my_therapy_pal/main.dart';

class AccountHomePage extends StatefulWidget {
  const AccountHomePage({Key? key}) : super(key: key);

  @override
  _AccountHomePageState createState() => _AccountHomePageState();
}

class _AccountHomePageState extends State<AccountHomePage> {
  final TextEditingController _noteController = TextEditingController();
  final notes = <String, String>{};
  final db = FirebaseFirestore.instance;
  late String uid;
  late String fname;
  late String sname;
  late String userType;
  late String? email;

  _getUser() async {
    if (FirebaseAuth.instance.currentUser != null) {
      uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
      fname = doc['fname'];
      sname = doc['sname'];
      userType = doc['userType'];
      email = FirebaseAuth.instance.currentUser!.email;
      db.collection("notes").where("uuid", isEqualTo: uid).get().then(
        (querySnapshot) {
          for (var docSnapshot in querySnapshot.docs) {
            String note = docSnapshot['note'];
            String noteId = docSnapshot.id;
            setState(() {
              notes[noteId] = note;
            });
          }
        },
        onError: (e) => print("Error completing: $e"),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  _saveNotes(newNote) async {
    try {
      final myNewDoc = await db.collection("notes").add({
        "uuid": uid,
        "note": newNote,
        "timestamp": Timestamp.now()
      });
      return myNewDoc.id.toString();
    } catch (e) {
      print(e);
      return null;
    }
  }

  _addNote() async {
    String newNote = _noteController.text;
    if (newNote.isNotEmpty) {
      final newNoteId = await _saveNotes(newNote);
      if (newNoteId != null) {
        setState(() {
          notes[newNoteId] = newNote;
        });
        _noteController.clear();
      }
    }
  }

  _deleteNote(String noteId) {
    db.collection("notes").where("uuid", isEqualTo: uid).get().then(
      (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          if (docSnapshot.id == noteId) {
            docSnapshot.reference.delete();
          }
        }
      },
      onError: (e) => print("Error completing: $e"),
    );
    setState(() {
      notes.remove(noteId);
    });
  }

  void _handleNavigationChange(int index) {
    setState(() {});

    // Navigate to the corresponding screen based on the index
    switch (index) {
      case 1:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ChatListScreen(),
          ),
        );
        break;
      case 2:
        AuthService().logoutUser();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
        break;
      // Add cases for additional screens as needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const NavDrawer(),
      appBar: AppBar(
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 12.0),
              child: Image.asset(
                'lib/assets/images/logo.png', // Replace with the actual path to your logo image
                height: 24, // Adjust the height as needed
              ),
            ),
            Text(
              const MainApp().title,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height / 40,
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(notes.values.elementAt(index)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () =>
                        _deleteNote(notes.keys.elementAt(index)),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Add a new note',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addNote,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: FluidNavBar(
          icons: [
            FluidNavBarIcon(
              icon: Icons.home,
              backgroundColor: Colors.purple,
              extras: {"label": "Home"},
            ),
            FluidNavBarIcon(
              icon: Icons.message,
              backgroundColor: Colors.indigo,
              extras: {"label": "Messages"},
            ),
            FluidNavBarIcon(
              icon: Icons.logout,
              backgroundColor: Colors.red[800],
              extras: {"label": "Logout"},
            ),
          ],
          onChange: _handleNavigationChange,
          style: const FluidNavBarStyle(
              iconUnselectedForegroundColor: Colors.white,
              iconSelectedForegroundColor: Colors.white,
              barBackgroundColor: Colors.teal),
          scaleFactor: 1.5,
          defaultIndex: 0,
          itemBuilder: (icon, item) => Semantics(
            label: icon.extras!["label"],
            child: item,
          ),
        ),
      ),
    );
  }
}
