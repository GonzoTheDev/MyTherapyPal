import 'package:flutter/material.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:my_therapy_pal/services/auth_service.dart';
import 'package:my_therapy_pal/widgets/nav_drawer.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/widgets/dashboard.dart';
import 'package:my_therapy_pal/widgets/chat_list.dart';
import 'package:my_therapy_pal/widgets/reports.dart';
import 'package:my_therapy_pal/widgets/listings.dart';
import 'package:my_therapy_pal/widgets/tasks.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AccountHomePage extends StatefulWidget {
  final int initialIndex; 
  const AccountHomePage({super.key, this.initialIndex = 0});

  @override
  State<AccountHomePage> createState() => _AccountHomePageState();
}

class _AccountHomePageState extends State<AccountHomePage> {
  
  Widget? _child;
  String _appBarSubtitle = "Home";

  @override
  void initState() {
    super.initState();
    _handleNavigationChange(widget.initialIndex);
  }
  
  @override
  void dispose() {
    super.dispose();
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
    if (index == 5) {
    // Show "are you sure" dialog before logging out
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog but not logout
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog and then logout
                logout();
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  } else {
      setState(() {
        switch (index) {
          case 0:
            _child = const Dashboard();
            _appBarSubtitle = "Dashboard"; 
            break;
          case 1:
            _child = const Reports();
            _appBarSubtitle = "Reports"; 
            break;
          case 2:
            _child = const ChatList();
            _appBarSubtitle = "Messages"; 
            break;
          case 3:
            _child = const Tasks();
            _appBarSubtitle = "Tasks";
            break;
          case 4:
            _child = const Listings();
            _appBarSubtitle = "Therapist Listings";
            break;
          case 5:
            logout();
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const NavDrawer(),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.teal,
          systemNavigationBarColor: Colors.teal,
          statusBarIconBrightness: Brightness.dark, 
          statusBarBrightness: Brightness.light, 
        ),
        title: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            // Get the screen width
            double screenWidth = MediaQuery.of(context).size.width;
            // Determine if the screen is small
            bool isSmallScreen = screenWidth < 800; 

            return Stack(
              alignment: Alignment.centerLeft,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
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
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(left: isSmallScreen ? 200 : 0),
                    child: Text(
                      _appBarSubtitle, 
                      style: const TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        centerTitle: false,
      ),


      body: _child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: FluidNavBar(
          icons: [
            FluidNavBarIcon(
              icon: Icons.home,
              backgroundColor: const Color(0xff6a32a5),
              extras: {"label": "Home"},
            ),
            FluidNavBarIcon(
              icon: Icons.insert_chart,
              backgroundColor: const Color(0xff0677ba),
              extras: {"label": "Reports"},
            ),
            FluidNavBarIcon(
              icon: Icons.message,
              backgroundColor: const Color(0xff62ca50),
              extras: {"label": "Messages"},
            ),
            FluidNavBarIcon(
              icon: Icons.task_alt,
              backgroundColor: const Color(0xffffd827),
              extras: {"label": "Tasks"},
            ),
            FluidNavBarIcon(
              icon: Icons.public,
              backgroundColor: const Color(0xfff78c37),
              extras: {"label": "Therapist Search"},
            ),
            FluidNavBarIcon(
              icon: Icons.logout,
              backgroundColor: const Color(0xffd42a34),
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
