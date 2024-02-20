import 'package:flutter/material.dart';


class Profile extends StatefulWidget {
  const Profile({Key? key}) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
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
    // TODO: implement build
    throw UnimplementedError();
      }
    }