import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_therapy_pal/models/mood_chart.dart';
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
          summaryText = querySnapshot.docs.first.data()['client_summary'];
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

  Future<List<MoodData>> getMoodDataForLast7Days() async {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    List<MoodData> moodData = [];
    try {
      var querySnapshot = await _firestore.collection('moods')
        .where('uid', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: startDate)
        .get();

    for (var doc in querySnapshot.docs) {
      DateTime timestamp = (doc['timestamp'] as Timestamp).toDate();
      String emoji = doc['emoji']; 
      moodData.add(MoodData(timestamp, emoji)); 
    }

    return moodData;
    } catch (e) {
      print('Error fetching mood data: $e');
      return [];
    }
    
  }

  Future<Map<DateTime, Map<String, int>>> aggregateMoodCounts() async {
    List<MoodData> moodDataList = await getMoodDataForLast7Days();
    Map<DateTime, Map<String, int>> aggregatedData = {};

    for (var moodData in moodDataList) {
      DateTime date = DateTime(moodData.timestamp.year, moodData.timestamp.month, moodData.timestamp.day);
      String emoji = moodData.emoji; 

      // Ensure the date map exists
      aggregatedData[date] ??= {};
      
      // Use a local variable for clarity and safety
      var emojiCount = aggregatedData[date]![emoji] ?? 0;
      aggregatedData[date]![emoji] = emojiCount + 1;
    }

    return aggregatedData;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center( // Center the content
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), // Limit the maximum width to 800 pixels
          child: Padding( // Apply padding on both sides
            padding: const EdgeInsets.symmetric(horizontal: 15), // Horizontal padding of 15 pixels
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                const SizedBox(height: 16),
                const Center( // Center the text
                              child:
                                Text(
                                  'Mood Summary',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                            ),
                const SizedBox(height: 16),
                Expanded(
                  flex: 1, // Adjust flex to control chart size
                  child: FutureBuilder<Map<DateTime, Map<String, int>>>(
                    future: aggregateMoodCounts(), // Assume this returns aggregated mood counts
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return MoodChart(snapshot.data!); // Pass aggregated data to the chart widget
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center( // Center the text
                              child:
                                Text(
                                  'Notes Summary',
                                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              summaryText,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class MoodData {
  final DateTime timestamp;
  final String emoji; 

  MoodData(this.timestamp, this.emoji); 
}