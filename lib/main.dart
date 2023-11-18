import 'package:flutter/material.dart';
import 'package:my_therapy_pal/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sizer/flutter_sizer.dart';

FirebaseAuth auth = FirebaseAuth.instance;

// Main program function
void main() async{
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
	runApp(const MainApp());
}

/*
passwordMatch(pwd1, pwd2) {
  if (pwd1 == pwd2) {
    return true;
  } else {
    return false;
  }
}

// Create a user in firebase
createUser(user, pass) async {
  try {
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: user,
      password: pass,
    );
} on FirebaseAuthException catch (e) {
  if (e.code == 'weak-password') {
    print('The password provided is too weak.');
  } else if (e.code == 'email-already-in-use') {
    print('The account already exists for that email.');
  }
} catch (e) {
  print(e);
}
}

// Login a user in firebase
loginUser(user, pass) async {

  await FirebaseAuth.instance.signInWithEmailAndPassword(
    email: user,
    password: pass
  );
  
}

// Logout a user in firebase
logoutUser() async {
  await FirebaseAuth.instance.signOut();
}
*/
// Main app widget
class MainApp extends StatelessWidget {
  final String title = 'MyTherapyPal';	
  const MainApp({Key? key}) : super(key: key);
	@override
	Widget build(BuildContext context) {
    return FlutterSizer(
      builder: (context, orientation, screenType) {
      return MaterialApp(
        title: title,
        theme: ThemeData(
          primarySwatch: Colors.cyan,
          scaffoldBackgroundColor: Color.fromARGB(255, 238, 235, 235),
        ),
        home: const Login(),
      );
	});
  }
}
/*
// Login widget
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
        child: 
        Padding(
          padding: const EdgeInsets.only(top: 32, bottom: 32, left: 8, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Login',
                style: TextStyle(color: Colors.black, fontSize: 20),
              ),
                Container(
                  padding:
                    const EdgeInsets.only(top: 32, bottom: 8, left: 8, right: 8),
                  width: Adaptive.w(50),
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
              Container(
                padding:
                    const EdgeInsets.only(top: 8, bottom: 32, left: 8, right: 8),
                width: Adaptive.w(50),
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
                    const EdgeInsets.only(top: 8, bottom: 8, left: 8, right: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        loginUser(emailController.text, passwordController.text);
                        User? user = FirebaseAuth.instance.currentUser;
                        // Navigate the user to the Home page
                          if (user != null) {
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
              Padding(
                padding:
                    const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Register(
                                title: 'Register',
                            )),
                          );
                        }, 
                    child: const Text('Register', style: TextStyle(color: Colors.white),),
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

// Register widget
class Register extends StatefulWidget {
  final String title;
  const Register({Key? key, required this.title}) : super(key: key);
	@override
	_RegisterState createState() => _RegisterState();
}
class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController fnameController = TextEditingController();
  TextEditingController snameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController pwd1Controller = TextEditingController();
  TextEditingController pwd2Controller = TextEditingController();

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
                  controller: pwd1Controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Password"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: TextFormField(
                  controller: pwd2Controller,
                  obscureText: true,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Confirm Password"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
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
                        if(passwordMatch(pwd1Controller.text, pwd2Controller.text)){
                          createUser(emailController.text, pwd1Controller.text);
                          User? user = FirebaseAuth.instance.currentUser;
                          // Navigate the user to the Home page
                          if (user!= null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Login(
                                  title: 'Login Page',
                              )),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User created successfully, please check your email to confirm your account!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password does not match')),
                              );
                          }
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

// Notes page widget
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Login(
                                title: 'Login Page',
                            )),
                          );
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
*/
