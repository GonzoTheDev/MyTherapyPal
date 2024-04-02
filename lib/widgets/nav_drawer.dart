import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/account_settings_screen.dart';
import 'package:my_therapy_pal/screens/admin/dashboard_screen.dart';
import 'package:my_therapy_pal/screens/app_settings_screen.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/screens/profile_settings_screen.dart';

class NavDrawer extends StatefulWidget {
  const NavDrawer({super.key});

  @override
  State<NavDrawer> createState() => _NavDrawerState();
}

class _NavDrawerState extends State<NavDrawer> {
  late Future<String> userType;

  @override
  void initState() {
    super.initState();
    userType = _getUserType();
  }

  Future<String> _getUserType() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userProfileDoc = await FirebaseFirestore.instance.collection('profiles').doc(uid).get();
    return userProfileDoc.data()?['userType'] ?? 'default';
  }

  Widget _addAdminMenuItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings),
      title: const Text('Admin Dashboard'),
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AdminHomePage(initialIndex: 0)),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<String>(
        future: userType,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userType = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
         DrawerHeader(
            decoration: const BoxDecoration(
                color: Colors.teal,
                ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 300,
                    height: 137,
                    child: Image.asset(
                      'assets/images/splash.png', 
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (userType == 'Admin') _addAdminMenuItem(context),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountHomePage(initialIndex: 0)),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart),
            title: const Text('Reports'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountHomePage(initialIndex: 1)),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountHomePage(initialIndex: 2)),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Tasks'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountHomePage(initialIndex: 3)),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Find a Therapist'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountHomePage(initialIndex: 4)),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const Profile()),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Account'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const ManageAccount()),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AppSettings()),
                (route) => false,
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () => {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AccountHomePage(initialIndex: 5)),
                (route) => false,
              ),
            },
          ),
        ],
      );
    }));
  }
}