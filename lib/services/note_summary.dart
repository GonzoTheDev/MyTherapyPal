import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class NoteSummary {

  Future<String> getNotesForLast7Days(String uid) async {
  try {
    // Calculate the date for 7 days ago
    final DateTime sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // Reference to the Firestore 'notes' collection
    final CollectionReference notesCollection = FirebaseFirestore.instance.collection('notes');

    // Query to get documents for the specified uid and within the last 7 days
    final QuerySnapshot querySnapshot = await notesCollection
        .where('uid', isEqualTo: uid)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
        .get();

    // Convert the query results to a List of Maps (which is essentially JSON)
    final List<Map<String, dynamic>> notes = querySnapshot.docs.map((doc) {
      return {
        'text': doc['text'],
        'timestamp': doc['timestamp'].toDate().toString(), 
        'title': doc['title'],
        'uid': doc['uid']
      };
    }).toList();

    // Convert the List<Map<String, dynamic>> to a JSON string
    final String notesJson = jsonEncode(notes);

    return notesJson;
  } catch (e) {
    // Return or handle the error
    // This could be logging the error or returning a custom error message
    // Here, we return a JSON string with an 'error' key and the error message
    final String errorJson = jsonEncode({'error': e.toString()});
    print('Error: $e');
    return errorJson;
  }
}

  // Method for making a request to the LLM API
  Future<String> llmResponse(String data) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/summary_api'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: data,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        return 'Error: Failed to load response, status code: ${response.statusCode}, please try again.';
      }
    } catch (e, stackTrace) {
      print('Error: Failed to make a request: $e');
      print('Stack trace: $stackTrace');
      return 'Error: Failed to make a request.';
    }
  }

  // Method to save the LLM response as a summary to Firestore
  Future<String> saveSummaryToFirestore(String clientSummary, String therapistSummary, String uid) async {

    // Reference to the Firestore note_summary collection
    final CollectionReference summaryCollection = FirebaseFirestore.instance.collection('note_summary');

    // Create the document data
    final Map<String, dynamic> summaryData = {
      'timestamp': Timestamp.fromDate(DateTime.now()), 
      'client_summary': clientSummary, 
      'therapist_summary': therapistSummary,
      'uid': uid, 
    };

    // Add the document to the collection
    await summaryCollection.add(summaryData).catchError((error) {
      print("Error saving summary to Firestore: $error");
      throw Exception("Error saving summary to Firestore: $error");
    });

    return 'Success'; 
  }
}