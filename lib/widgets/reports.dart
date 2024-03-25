import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/services/note_summary.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  late final NoteSummary noteSummary;
  String summaryText = "Loading summary...";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    noteSummary = NoteSummary();
    checkAndGenerateSummary();
  }

  Future<void> checkAndGenerateSummary() async {
    // Fetching the most recent summary, regardless of the need to generate a new one
    var querySnapshot = await _firestore.collection('note_summary')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    
    if (querySnapshot.docs.isEmpty) {
      // If there are no summaries, begin the process to generate a new one
      generateNewSummary();
    } else {
      // If there is at least one summary, check its timestamp
      Timestamp lastSummaryTimestamp = querySnapshot.docs.first.data()['timestamp'];
      DateTime lastSummaryDate = lastSummaryTimestamp.toDate();
      DateTime now = DateTime.now();
       
      if (now.difference(lastSummaryDate).inHours > 24) {
        // If the last summary is older than 24 hours, generate a new summary
        generateNewSummary();
      } else {
        // Otherwise, set the text to the most recent summary's content
        setState(() {
          summaryText = querySnapshot.docs.first.data()['summary'];
        });
      }
    }
  }

  Future<void> generateNewSummary() async {
    String notesJson = await noteSummary.getNotesForLast7Days(uid);
    if (notesJson == '[]') {
      setState(() {
        summaryText = 'No notes found for the last 7 days.';
      });
      return;
    }
    print("Notes JSON: $notesJson");
    String llmApiResponse = await noteSummary.llmResponse(notesJson);

    // Decode the JSON response
    Map<String, dynamic> decodedResponse = jsonDecode(llmApiResponse);
    
    // Extract the 'summary_response' value
    var summaryContent = decodedResponse['summary_response'];

    String therapistSummary = summaryContent['therapist_summary'];
    String clientSummary = summaryContent['client_summary'];
    
    if(llmApiResponse.startsWith('Error')) {
      setState(() {
        summaryText = llmApiResponse;
      });
      return;
    }
    await noteSummary.saveSummaryToFirestore(clientSummary, therapistSummary, uid);
    setState(() {
      summaryText = clientSummary;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Weekly Notes Summary',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(summaryText),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
