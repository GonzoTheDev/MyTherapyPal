import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageListings extends StatelessWidget {
  const ManageListings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('User ID')),
                  DataColumn(label: Text('First Name')),
                  DataColumn(label: Text('Last Name')),
                  DataColumn(label: Text('Address')),
                  DataColumn(label: Text('Disciplines')),
                  DataColumn(label: Text('Rates From')),
                  DataColumn(label: Text('Rates To')),
                  DataColumn(label: Text('Active')),
                  DataColumn(label: Text('Update Status')),
                  DataColumn(label: Text('Approved')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Profile Picture')),
                  DataColumn(label: Text('Delete')),
                ],
                rows: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
                  return DataRow(cells: [
                    DataCell(Text(data['uid'])),
                    DataCell(Text(data['fname'])),
                    DataCell(Text(data['sname'])),
                    DataCell(Text(data['address'])),
                    DataCell(Text(data['disciplines'].join(', '))),
                    DataCell(Text(data['ratesFrom'])),
                    DataCell(Text(data['ratesTo'])),
                    DataCell(Icon(data['active'] ? Icons.check : Icons.close, color: data['active'] ? Colors.green : Colors.red)),
                    DataCell(Switch(
                      value: data['active'],
                      onChanged: (bool value) {
                        document.reference.update({'active': value});
                      },
                    )),
                    DataCell(Switch(
                      value: data['approved'],
                      onChanged: (bool value) {
                        document.reference.update({'approved': value});
                      },
                    )),
                    DataCell(ElevatedButton(
                      child: const Text('View'),
                      onPressed: () => launchUrl(Uri.parse('https://maps.google.com/?q=${data['location'].latitude},${data['location'].longitude}')),
                    )),
                    DataCell(ElevatedButton(
                      child: const Text('View'),
                      onPressed: () => launchUrl(Uri.parse(data['pic_url'])),
                    )),
                    DataCell(ElevatedButton(
                      child: const Text('Delete'),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirm'),
                            content: const Text('Are you sure you want to delete this listing?'),
                            actions: <Widget>[
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () {
                                  document.reference.delete().then((_) => Navigator.of(context).pop());
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
