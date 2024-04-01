import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:my_therapy_pal/screens/admin/widgets/manage_user.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers({super.key});

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  Future<List<UserRecord>>? _userListFuture;

  @override
  void initState() {
    super.initState();
    _userListFuture = listAllUsers();
  }

  Future<List<UserRecord>> listAllUsers() async {
    final functions = FirebaseFunctions.instance;
    
    try {
      final HttpsCallableResult result = await functions.httpsCallable('listAllUsers').call();
      final Map<String, dynamic> data = Map<String, dynamic>.from(result.data);
      final List<dynamic> usersData = List<dynamic>.from(data['users'] ?? []);
      List<UserRecord> users = usersData.map<UserRecord>((user) => UserRecord.fromJson(Map<String, dynamic>.from(user))).toList();

      // Sort the users by their creation timestamp
      // Assuming earlier dates should come first, otherwise, swap the comparison operands
      users.sort((a, b) => b.creationTimestamp.compareTo(a.creationTimestamp));

      return users;
    } catch (e) {
      print(e);
      throw Exception('Failed to fetch users');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<UserRecord>>(
        future: _userListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final user = snapshot.data![index];
                return ListTile(
                  title: Text(user.email),
                  subtitle: Text('UUID: ${user.uuid}'),
                  trailing: Wrap(
                    spacing: 12, // space between two icons
                    children: <Widget>[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Created: ${user.creationTimestamp.toString()}'),
                          Text('Last Login: ${user.lastLoginTimestamp.toString()}'),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.manage_accounts),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ManageUserScreen(userId: user.uuid)),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No users found.'));
          }
        },
      ),
    );
  }
}

class UserRecord {
  final String uuid;
  final String email;
  final DateTime creationTimestamp;
  final DateTime lastLoginTimestamp;

  UserRecord({
    required this.uuid,
    required this.email,
    required this.creationTimestamp,
    required this.lastLoginTimestamp,
  });

  factory UserRecord.fromJson(Map<String, dynamic> json) {
    final DateFormat formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss \'GMT\'');
    
    // Providing default values if any field is null
    final String uuid = json['uid'] as String? ?? 'Unknown';
    final String email = json['email'] as String? ?? 'No email provided';
    DateTime creationTimestamp;
    DateTime lastLoginTimestamp;

    // Attempt to parse the dates if they're not null; otherwise, use a default value
    try {
      creationTimestamp = json['metadata']['creationTime'] != null 
        ? formatter.parse(json['metadata']['creationTime'], true).toLocal() 
        : DateTime.now();
      lastLoginTimestamp = json['metadata']['lastSignInTime'] != null 
        ? formatter.parse(json['metadata']['lastSignInTime'], true).toLocal() 
        : DateTime.now();
    } catch (e) {
      // If parsing fails, default to the current time. Adjust this as necessary.
      creationTimestamp = DateTime.now();
      lastLoginTimestamp = DateTime.now();
    }

    return UserRecord(
      uuid: uuid,
      email: email,
      creationTimestamp: creationTimestamp,
      lastLoginTimestamp: lastLoginTimestamp,
    );
  }
}