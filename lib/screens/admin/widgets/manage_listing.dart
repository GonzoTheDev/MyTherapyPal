import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageListingScreen extends StatefulWidget {
  final DocumentSnapshot listingDocument;

  const ManageListingScreen({super.key, required this.listingDocument});

  @override
  State<ManageListingScreen> createState() => _ManageListingScreenState();
}

class _ManageListingScreenState extends State<ManageListingScreen> {
  late bool isActive;
  late bool isApproved;

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> data = widget.listingDocument.data()! as Map<String, dynamic>;
    isActive = data['active'];
    isApproved = data['approved'];
  }

  void toggleActiveStatus() async {
    setState(() {
      isActive = !isActive;
    });
    await widget.listingDocument.reference.update({'active': isActive});
  }

  void toggleApprovedStatus() async {
    setState(() {
      isApproved = !isApproved;
    });
    await widget.listingDocument.reference.update({'approved': isApproved});
  }

  Future<void> deleteListing() async {
    final bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm'),
              content: const Text('Are you sure you want to delete this listing?'),
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
      await widget.listingDocument.reference.delete();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data = widget.listingDocument.data()! as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Listing: ${data['uid']}'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('User ID'),
            subtitle: Text(data['uid']),
          ),
          ListTile(
            title: const Text('First Name'),
            subtitle: Text(data['fname']),
          ),
          ListTile(
            title: const Text('Last Name'),
            subtitle: Text(data['sname']),
          ),
          ListTile(
            title: const Text('Address'),
            subtitle: Text(data['address']),
          ),
          ListTile(
            title: const Text('Disciplines'),
            subtitle: Text(data['disciplines'].join(', ')),
          ),
          ListTile(
            title: const Text('Rates From'),
            subtitle: Text(data['ratesFrom']),
          ),
          ListTile(
            title: const Text('Rates To'),
            subtitle: Text(data['ratesTo']),
          ),
          ListTile(
            title: const Text('Update Status'),
            trailing: Switch(
              value: isActive,
              onChanged: (bool value) {}, // Intentionally blank; toggling is handled by onTap
            ),
            onTap: toggleActiveStatus,
          ),
          ListTile(
            title: const Text('Approved'),
            trailing: Switch(
              value: isApproved,
              onChanged: (bool value) {}, // Intentionally blank; toggling is handled by onTap
            ),
            onTap: toggleApprovedStatus,
          ),
          ListTile(
            title: const Text('Location'),
            trailing: const Icon(Icons.map),
            onTap: () => launchUrl(Uri.parse('https://maps.google.com/?q=${data['location'].latitude},${data['location'].longitude}')),
          ),
          ListTile(
            title: const Text('Profile Picture'),
            trailing: const Icon(Icons.image),
            onTap: () => launchUrl(Uri.parse(data['pic_url'])),
          ),
          ListTile(
            title: const Text('Delete'),
            trailing: const Icon(Icons.delete),
            onTap: deleteListing,
          ),
        ],
      ),
    );
  }
}
