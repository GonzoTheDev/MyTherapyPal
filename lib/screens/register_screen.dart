import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import '../services/auth_service.dart';

class RegisterAccount extends StatefulWidget {
  const RegisterAccount({super.key});

  @override
  State<RegisterAccount> createState() => _RegisterAccountState();
}

class _RegisterAccountState extends State<RegisterAccount> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _snameController = TextEditingController();
  String dropdownvalue = ''; 
  var items = ['', 'Patient', 'Therapist'];

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
            Text(
              const MainApp().title,
              style: const TextStyle(color: Colors.white),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(color: Colors.black, fontSize: 30),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter your details below to create a new account.',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 30,
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
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
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
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    const Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 10,
                      endIndent: 10,
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _fnameController,
                      decoration: InputDecoration(
                        hintText: 'First Name',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    TextFormField(
                      controller: _snameController,
                      decoration: InputDecoration(
                        hintText: 'Last Name',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal, width: 1.0),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    DropdownButtonFormField(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.teal),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      value: dropdownvalue.isNotEmpty ? dropdownvalue : null,
                      items: items.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownvalue = newValue!;
                        });
                      },
                      hint: const Text("Select User Type"),
                    ),
                    const SizedBox(height: 30.0),
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: () async {
                          final message = await AuthService().registration(
                            email: _emailController.text,
                            password: _passwordController.text,
                            passwordConfirm: _passwordConfirmController.text,
                            fname: _fnameController.text,
                            sname: _snameController.text,
                            userType: dropdownvalue,
                          );
                          if (message!.contains('Success')) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => 
                                  const Login()
                              )
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message),
                            ),
                          );
                        },
                        style: ButtonStyle(
                          minimumSize: MaterialStateProperty.all<Size>(const Size(double.infinity, 36)),
                        ),
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    // Optionally add more widgets or logic as needed
                  ],
                ),
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
    _passwordConfirmController.dispose();
    _fnameController.dispose();
    _snameController.dispose();
    super.dispose();
  }
}
