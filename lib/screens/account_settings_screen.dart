import 'package:flutter/material.dart';


class ManageAccount extends StatefulWidget {
  const ManageAccount({super.key});

  @override
  State<ManageAccount> createState() => _ManageAccount();
}

class _ManageAccount extends State<ManageAccount> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Account'),
      ),
      body: const Center(
        child: Text('This page needs to be implemented.'),
      ),
    );
  }
}