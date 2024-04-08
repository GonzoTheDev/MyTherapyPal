import 'package:flutter/material.dart';


class AppSettings extends StatefulWidget {
  const AppSettings({super.key});

  @override
  State<AppSettings> createState() => _AppSettings();
}

class _AppSettings extends State<AppSettings> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('This page needs to be implemented.'),
      ),
    );
  }
}