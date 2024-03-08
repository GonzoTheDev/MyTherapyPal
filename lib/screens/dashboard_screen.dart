import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/screens/admin/dashboard_screen.dart';
import 'package:my_therapy_pal/screens/login_screen.dart';
import 'package:my_therapy_pal/services/auth_service.dart';
import 'package:my_therapy_pal/widgets/nav_drawer.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/widgets/dashboard.dart';
import 'package:my_therapy_pal/widgets/chat_list.dart';
import 'package:my_therapy_pal/widgets/records.dart';
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
  bool _showFab = false;
  String _appBarSubtitle = "Home";

  @override
  void initState() {
    super.initState();
    checkIsAdmin();
    _handleNavigationChange(widget.initialIndex);
  }
  
  @override
  void dispose() {
    super.dispose();
  }


  void checkIsAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
      final userType = userProfileDoc.data()?['userType'];
      if (userType == "Admin") {
        if(mounted) {
          setState(() {
            _showFab = true;
          });
        }
      } else {
        if(mounted) {
          setState(() {
            _showFab = false;
          });
        }
      }
    }
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
          _appBarSubtitle = "Home"; 
          break;
        case 1:
          _child = const Records();
          _appBarSubtitle = "Records"; 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const NavDrawer(),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.teal,
          systemNavigationBarColor: Colors.teal,
          statusBarIconBrightness: Brightness.dark, // For Android
          statusBarBrightness: Brightness.light, // For iOS
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
                      _appBarSubtitle, // The subtitle
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
              extras: {"label": "Records"},
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
      floatingActionButton: _showFab ? FloatingActionButton(
        onPressed: () {
          // Navigate to StartChat or the action you want to perform
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
          );
        },
        tooltip: 'Go to Admin Dashboard',
        child: const Icon(Icons.add),
      ) : null, // Hide FAB when not on ChatList
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
