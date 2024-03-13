import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/screens/admin/widgets/manage_listing.dart';

class ManageListings extends StatelessWidget {
  const ManageListings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          final data = snapshot.requireData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0), 
                child: Text(
                  'Manage Listings',
                  style: Theme.of(context).textTheme.titleLarge, 
                ),
              ),
              Expanded( 
                child: ListView.builder(
                itemCount: data.size,
                itemBuilder: (context, index) {
                  String uid = data.docs[index]['uid'];
                  return ListTile(
                    title: Text("UID: $uid"),
                    subtitle: Row(
                      children: [
                        const Text('Active: '),
                        Icon(
                          data.docs[index]['active'] ? Icons.check : Icons.close,
                          color: data.docs[index]['active'] ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 20), 
                        const Text('Approved: '),
                        Icon(
                          data.docs[index]['approved'] ? Icons.check : Icons.close,
                          color: data.docs[index]['approved'] ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ManageListingScreen(listingDocument: data.docs[index]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}