import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluid_bottom_nav_bar/fluid_bottom_nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:my_therapy_pal/screens/admin/widgets/admin_dashboard.dart';
import 'package:my_therapy_pal/screens/admin/widgets/manage_chat_list.dart';
import 'package:my_therapy_pal/screens/admin/widgets/manage_listings.dart';
import 'package:my_therapy_pal/screens/admin/widgets/manage_messages.dart';
import 'package:my_therapy_pal/screens/admin/widgets/manage_users.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/widgets/nav_drawer.dart';
import 'package:my_therapy_pal/main.dart';
import 'package:my_therapy_pal/widgets/start_chat.dart';


class AdminHomePage extends StatefulWidget {
  final int initialIndex; 
  const AdminHomePage({super.key, this.initialIndex = 0});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  
  Widget? _child;
  bool _showFab = false;
  String? uid;

  // Initialize the Firestore database instance
  final FirebaseFirestore db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _handleNavigationChange(widget.initialIndex);
  }

  void checkIsAdmin() async {

    // Get the user's profile data
    uid = FirebaseAuth.instance.currentUser!.uid;
    final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
    final userType = userProfileDoc['userType'];

      if (userType != "Admin") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AccountHomePage()),
        );
      } 
  }	

  void _handleNavigationChange(int index) {
    setState(() {
      _showFab = index == 2;
      switch (index) {
        case 0:
          _child = const AdminDashboard();
          break;
        case 1:
          _child = const ManageUsers();
          break;
        case 2:
          _child = const ManageChatList();
          break;
        case 3:
          _child = const ManageMessages();
          break; 
        case 4:
          _child = const ManageListings();
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
      body: _child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: FluidNavBar(
          icons: [
            FluidNavBarIcon(
              icon: Icons.home,
              backgroundColor: Colors.green,
              extras: {"label": "Admin Dashboard"},
            ),
            FluidNavBarIcon(
              icon: Icons.account_box,
              backgroundColor: Colors.blue,
              extras: {"label": "Manage Users"},
            ),
            FluidNavBarIcon(
              icon: Icons.forum,
              backgroundColor: Colors.indigo,
              extras: {"label": "Manage Chat List"},
            ),
            FluidNavBarIcon(
              icon: Icons.message,
              backgroundColor: Colors.purple[800],
              extras: {"label": "Manage Messages"},
            ), 
            FluidNavBarIcon(
              icon: Icons.list,
              backgroundColor: Colors.red[800],
              extras: {"label": "Manage Listings"},
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
            MaterialPageRoute(builder: (context) => const StartChat()),
          );
        },
        tooltip: 'Start new chat',
        child: const Icon(Icons.add),
      ) : null, // Hide FAB when not on ChatList
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
