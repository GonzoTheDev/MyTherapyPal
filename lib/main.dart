import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() {
	runApp(NoteApp());
}
class NoteApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Note Taking App',
			theme: ThemeData(
				primarySwatch: Colors.blue,
			),
			home: NoteHomePage(),
		);
	}
}
class NoteHomePage extends StatefulWidget {
	@override
	_NoteHomePageState createState() => _NoteHomePageState();
}
class _NoteHomePageState extends State < NoteHomePage > {
	final TextEditingController _noteController = TextEditingController();
	final List < String > _notes = [];
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
				title: Text('Note Taking App'),
			),
			body: Column(
				children: < Widget > [
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
				],
			),
		);
	}
}