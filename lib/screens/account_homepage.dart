import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_therapy_pal/screens/chat.dart';
import 'package:my_therapy_pal/widgets/nav-drawer.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/login.dart';
import 'package:my_therapy_pal/main.dart';

// Notes page widget
class AccountHomePage extends StatefulWidget {
  const AccountHomePage({Key? key}) : super(key: key);
	@override
	_AccountHomePageState createState() => _AccountHomePageState();
}
class _AccountHomePageState extends State < AccountHomePage > {
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
      final doc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
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
  
	@override
	Widget build(BuildContext context) {
		return Scaffold(
      drawer: NavDrawer(),
			appBar: AppBar(
				title: Text(
            const MainApp().title,
            style: const TextStyle(color: Colors.white),
          ),
			),
			body: Column( 
				children: < Widget > [
          SizedBox(
              height: MediaQuery.of(context).size.height / 40,
              ),
          const Text(
              'My Account',
              style: TextStyle(color: Colors.black, fontSize: 20,),
            ),
					Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                // String inputText = notes.values.elementAt(index);
                // You can remove the above line as well, as it's not needed now
                return ListTile(
                  title: Text(notes.values.elementAt(index)),
                  // Commented out code related to predictedEmotion
                  // FutureBuilder<String>(
                  //   future: predictEmotion(inputText),
                  //   builder: (context, snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.waiting) {
                  //       return const CircularProgressIndicator();
                  //     } else if (snapshot.hasError) {
                  //       return Text('Error: ${snapshot.error}');
                  //     } else {
                  //       String predictedEmotion = snapshot.data ?? 'Unknown Emotion';
                  //       return ListTile(
                  //         title: Text(notes.values.elementAt(index)),
                  //         subtitle: Text('Emotion: $predictedEmotion'),
                  //         trailing: IconButton(
                  //           icon: const Icon(Icons.delete),
                  //           onPressed: () => _deleteNote(notes.keys.elementAt(index)),
                  //         ),
                  //       );
                  //     }
                  //   },
                  // ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNote(notes.keys.elementAt(index)),
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
            Padding(
                padding:
                    const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              child: const Text('Create New Account'),
                  ),
                ),
              ),
          Padding(
                padding:
                    const EdgeInsets.only(top: 4, bottom: 8, left: 8, right: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                          AuthService().logoutUser();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const Login()),
                            (route) => false);
                        }, 
                    child: const Text('Logout', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ),
				],
			),
		);
	}
}
