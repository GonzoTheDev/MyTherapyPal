import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Notes extends StatefulWidget {
  const Notes({Key? key}) : super(key: key);

  @override
  _NotesState createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  final notes = <String, String>{};
  final db = FirebaseFirestore.instance;
  final TextEditingController _noteController = TextEditingController();
  late String uid;
  late String fname;
  late String sname;
  late String userType;
  late String? email;

  @override
  void initState() {
    super.initState();
    _getUser();
  }

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
    
  _saveNotes(newNote) async {
    try {
      final myNewDoc = await db.collection("notes").add({
        "uuid": uid,
        "note": newNote,
        "timestamp": Timestamp.now(),
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
    db.collection("notes").doc(noteId).delete();
    setState(() {
      notes.remove(noteId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}
