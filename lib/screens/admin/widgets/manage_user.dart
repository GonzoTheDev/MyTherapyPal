import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUserScreen extends StatefulWidget {
  final String userId;

  const ManageUserScreen({super.key, required this.userId});

  @override
  State<ManageUserScreen> createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  DocumentSnapshot? userProfile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  void fetchUserProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('profiles').doc(widget.userId).get();
      if (doc.exists) {
        setState(() {
          userProfile = doc;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print(e); 
    }
  }

  Future<void> deleteUser() async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Are you sure you want to delete this user and all associated data?'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      // Placeholder for delete logic across multiple collections
      print('Delete user and associated data here');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = {};
    // Check if isLoading or userProfile is null
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: isLoading ? const CircularProgressIndicator() : const Text("User profile not found."),
        ),
      );
    }

    if(userProfile == null) {
      data = {'uid': widget.userId};
    }else{
      data = userProfile!.data()! as Map<String, dynamic>;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage User: ${data['uid']}'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('First Name'),
            subtitle: Text(data['fname'] ?? 'N/A'), 
          ),
          ListTile(
            title: const Text('Last Name'),
            subtitle: Text(data['sname'] ?? 'N/A'), 
          ),
          ListTile(
            title: const Text('User Type'),
            subtitle: Text(data['userType'] ?? 'N/A'), 
          ),
          ListTile(
            title: const Text('Delete User'),
            trailing: const Icon(Icons.delete),
            onTap: deleteUser,
          ),
        ],
      ),
    );
  }

}
