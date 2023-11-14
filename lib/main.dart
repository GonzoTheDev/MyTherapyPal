import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
	runApp(MainApp());
}
class MainApp extends StatelessWidget {
  const MainApp({Key? key}) : super(key: key);
	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'MyTherapyPal',
			theme: ThemeData(
				primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Color.fromARGB(255, 238, 235, 235),
			),
			home: const Login(title: 'MyTherapyPal'),
		);
	}
}
class Login extends StatefulWidget {
  final String title;
  const Login({Key? key, required this.title}) : super(key: key);
	@override
	_LoginState createState() => _LoginState();
}
class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.title,
            style: const TextStyle(color: Colors.white),
          ),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Password"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Navigate the user to the Home page
                        if (emailController.text == "sbw92@outlook.com" && passwordController.text == "test") {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoteHomePage(
                                title: 'Notes Page',
                                email: emailController.text,
                            )),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid Credentials')),
                            );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill input')),
                        );
                      }
                    },
                    child: const Text('Submit', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class NoteHomePage extends StatefulWidget {
  const NoteHomePage({super.key, required this.email, required this.title});
  final String email;
  final String title;
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
          Text(widget.email),
          Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Go back!"),
              ),
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
				],
			),
		);
	}
}
