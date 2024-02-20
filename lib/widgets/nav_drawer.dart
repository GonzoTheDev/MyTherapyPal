import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/account_settings_screen.dart';
import 'package:my_therapy_pal/screens/app_settings_screen.dart';
import 'package:my_therapy_pal/screens/dashboard_screen.dart';
import 'package:my_therapy_pal/screens/profile_settings_screen.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
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
                      'lib/assets/images/splash.png', // Adjust the path based on your actual file structure
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const AccountHomePage(initialIndex: 0),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_chart),
            title: const Text('Records'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const AccountHomePage(initialIndex: 1),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Messages'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const AccountHomePage(initialIndex: 2),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('Find a Therapist'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const AccountHomePage(initialIndex: 3),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Profile'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const Profile(),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.manage_accounts),
            title: const Text('Account'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const ManageAccount(),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const AppSettings(),
                ),
              ),
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Logout'),
            onTap: () => {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => const AccountHomePage(initialIndex: 4),
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}