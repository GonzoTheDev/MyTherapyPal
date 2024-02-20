import 'package:flutter/material.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:my_therapy_pal/services/auth_service.dart';
import 'package:my_therapy_pal/widgets/nav_drawer.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/widgets/dashboard.dart';
import 'package:my_therapy_pal/widgets/chat_list.dart';
import 'package:my_therapy_pal/widgets/records.dart';
import 'package:my_therapy_pal/widgets/listings.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AccountHomePage extends StatefulWidget {
  final int initialIndex; 
  const AccountHomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _AccountHomePageState createState() => _AccountHomePageState();
}

class _AccountHomePageState extends State<AccountHomePage> {
  
  Widget? _child;
  

  @override
  void initState() {
    super.initState();
    _handleNavigationChange(widget.initialIndex);
  }

  Future<void> logout() async {

    // Logout the user from firebase authentication
    AuthService().logoutUser();

    // Obtain shared preferences.
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Remove the users private key from shared preferences
    await prefs.remove('privateKeyRSA');

    // Send the user back to the login screen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const Login()),
      (route) => false,
    );
  }

  void _handleNavigationChange(int index) {
    setState(() {
      switch (index) {
        case 0:
          _child = const Dashboard();
          break;
        case 1:
          _child = const Records();
          break;
        case 2:
          _child = const ChatList();
          break;
        case 3:
          _child = const Listings();
          break; 
        case 4:
          logout();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const NavDrawer(),
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
                'lib/assets/images/logo.png', 
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
      body: _child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: FluidNavBar(
          icons: [
            FluidNavBarIcon(
              icon: Icons.home,
              backgroundColor: Colors.green,
              extras: {"label": "Home"},
            ),
            FluidNavBarIcon(
              icon: Icons.insert_chart,
              backgroundColor: Colors.blue,
              extras: {"label": "Records"},
            ),
            FluidNavBarIcon(
              icon: Icons.message,
              backgroundColor: Colors.indigo,
              extras: {"label": "Messages"},
            ),
            FluidNavBarIcon(
              icon: Icons.public,
              backgroundColor: Colors.purple,
              extras: {"label": "Therapist Search"},
            ),
            FluidNavBarIcon(
              icon: Icons.logout,
              backgroundColor: Colors.red[800],
              extras: {"label": "Logout"},
            ),
          ],
          onChange: _handleNavigationChange,
          style: const FluidNavBarStyle(
              iconUnselectedForegroundColor: Colors.white,
              iconSelectedForegroundColor: Colors.white,
              barBackgroundColor: Colors.teal),
          scaleFactor: 1.5,
          defaultIndex: widget.initialIndex,
          itemBuilder: (icon, item) => Semantics(
            label: icon.extras!["label"],
            child: item,
          ),
        ),
      ),
    );
  }
}
