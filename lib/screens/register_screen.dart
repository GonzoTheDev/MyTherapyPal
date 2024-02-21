import 'package:flutter/services.dart';
import 'package:my_therapy_pal/main.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:flutter/material.dart';


class RegisterAccount extends StatefulWidget {
  const RegisterAccount({super.key});

  @override
  State<RegisterAccount> createState() => _RegisterAccountState();
}

class _RegisterAccountState extends State<RegisterAccount> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController = TextEditingController();
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _snameController = TextEditingController();

    // Initial Selected Value 
  String dropdownvalue = '';    
  
  // List of items in our dropdown menu 
  var items = [     
    '',
    'Patient', 
    'Therapist', 
    'Admin', 
  ]; 

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
        title: Text(
            const MainApp().title,
            style: const TextStyle(color: Colors.white),
          ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 10,
              ),
            const Text(
                'Sign Up',
                style: TextStyle(color: Colors.black, fontSize: 20,),
              ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 20,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(hintText: 'Email'),
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                ),
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _passwordConfirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Confirm Password',
                ),
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _fnameController,
                decoration: const InputDecoration(
                  hintText: 'First Name',
                ),
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: TextField(
                controller: _snameController,
                decoration: const InputDecoration(
                  hintText: 'Last Name',
                ),
              ),
            ),
            const SizedBox(
              height: 30.0,
            ),
            const Text(
              'Please select your user type: ',
              style: TextStyle(color: Colors.black, fontSize: 20,),
            ),
            DropdownButton( 
              
              
              // Initial Value 
              value: dropdownvalue.isNotEmpty ? dropdownvalue : null, 
                
              // Down Arrow Icon 
              icon: const Icon(Icons.keyboard_arrow_down),

              style: const TextStyle(color: Colors.white),
              dropdownColor: Colors.teal,        
                
              // Array list of items 
              items: items.map((String items) { 
                return DropdownMenuItem( 
                  value: items, 
                  child: Text(items), 
                ); 
              }).toList(), 
              // After selecting the desired option,it will 
              // change button value to selected value 
              onChanged: (String? newValue) {  
                setState(() { 
                  dropdownvalue = newValue!; 
                }); 
              }, 
            ), 
            const SizedBox(
              height: 30.0,
            ),
            ElevatedButton(
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
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}