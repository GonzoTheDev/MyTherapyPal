import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart';
import 'register_screen.dart';
import '../services/auth_service.dart';
import 'dashboard_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AccountHomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
        // Status bar color
        statusBarColor: Colors.teal, 
        systemNavigationBarColor: Colors.teal,
        // Status bar brightness (optional)
        statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
        statusBarBrightness: Brightness.light, // For iOS (dark icons)
        ),
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
      body: Center(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height / 10,
                ),
                const Text(
                  'Login',
                  style: TextStyle(color: Colors.black, fontSize: 20),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 20,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(hintText: 'Email'),
                    autofillHints: [AutofillHints.email],
                    onFieldSubmitted: (value) {
                    if (_passwordController.text.isNotEmpty) {
                      _submitForm();
                    } else {
                      FocusScope.of(context).requestFocus(_passwordFocusNode);
                    }
                  },
                  ),
                ),
                const SizedBox(
                  height: 30.0,
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 2,
                  child: TextFormField(
                    focusNode: _passwordFocusNode,
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'Password'),
                    autofillHints: [AutofillHints.password],
                    onFieldSubmitted: (value) {
                      _submitForm();
                    },
                  ),
                ),
                const SizedBox(
                  height: 30.0,
                ),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(
                  height: 30.0,
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
