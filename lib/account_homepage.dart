import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Notes page widget
class AccountHomePage extends StatefulWidget {
  const AccountHomePage({super.key, required this.title});
  final String title;
	@override
	_AccountHomePageState createState() => _AccountHomePageState();
}
class _AccountHomePageState extends State < AccountHomePage > {
	final TextEditingController _noteController = TextEditingController();
	final List < String > _notes = [];
  
  // Logout a user in firebase
  logoutUser() async {
    await FirebaseAuth.instance.signOut();
  }
  
	@override
	void initState() {
		super.initState();
		_loadNotes();
	}
	_loadNotes() async {
		SharedPreferences prefs = await SharedPreferences.getInstance();
		setState(() {
			_notes.addAll(prefs.getStringList('notes') ?? []);
		});
	}
	_saveNotes() async {
		SharedPreferences prefs = await SharedPreferences.getInstance();
		prefs.setStringList('notes', _notes);
	}
	_addNote() {
		String newNote = _noteController.text;
		if (newNote.isNotEmpty) {
			setState(() {
				_notes.add(newNote);
			});
			_noteController.clear();
			_saveNotes();
		}
	}
	_deleteNote(int index) {
		setState(() {
			_notes.removeAt(index);
		});
		_saveNotes();
	}
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text(
            'MyTherapyPal',
            style: TextStyle(color: Colors.white),
          ),
			),
			body: Column( 
				children: < Widget > [
          Text(
            widget.title,
            style: TextStyle(fontSize: 20),
          ),
					Expanded(
						child: ListView.builder(
							itemCount: _notes.length,
							itemBuilder: (context, index) {
								return ListTile(
									title: Text(_notes[index]),
									trailing: IconButton(
										icon: Icon(Icons.delete),
										onPressed: () => _deleteNote(index),
									),
								);
							},
						),
					),
					Padding(
						padding: EdgeInsets.all(8.0),
						child: TextField(
							controller: _noteController,
							decoration: InputDecoration(
								labelText: 'Add a new note',
								suffixIcon: IconButton(
									icon: Icon(Icons.add),
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
                          logoutUser();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const Login(title: 'Login Page')),
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
