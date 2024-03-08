import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/screens/reset_password.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final message = await AuthService().login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (message!.contains('Success')) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AccountHomePage()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      }
    }
  }

  void checkLoginStatus() async {
    FirebaseAuth.instance
    .authStateChanges()
    .listen((User? user) {
      if (user == null) {
        // User is not logged in
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AccountHomePage()),
        );
      }
    });
  }  

  @override
  Widget build(BuildContext context) {
    double maxWidth = MediaQuery.of(context).size.width > 414 ? 414 : MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.teal,
          systemNavigationBarColor: Colors.teal,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 12.0),
              child: Image.asset(
                'assets/images/logo.png',
                height: 24,
              ),
            ),
            const Text(
              MainApp.title,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Center(
        child: AutofillGroup(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth / 1.2),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 10,
                  ),
                  const Text(
                    'Welcome',
                    style: TextStyle(color: Colors.black, fontSize: 30),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your login details to sign in.',
                    style: TextStyle(color: Colors.black, fontSize: 15),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 20,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      filled: true, 
                      fillColor: Colors.grey[50], 
                      border: OutlineInputBorder( 
                        borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (value) {
                      if (_passwordController.text.isNotEmpty) {
                        _submitForm();
                      } else {
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      }
                    },
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  TextFormField(
                    focusNode: _passwordFocusNode,
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true, 
                      fillColor: Colors.grey[50], 
                      border: OutlineInputBorder( 
                        borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (value) {
                      _submitForm();
                    },
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ResetPassword(),
                            ),
                          );
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ButtonStyle(
                        minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 36)),
                      ),
                      child: const Text(
                        'SIGN IN',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    children: [
                      const Text(
                        "Don't have an account?",
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterAccount(),
                            ),
                          );
                        },
                        child: const Text('Create New Account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
