import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> predictEmotion(String text) async {
  final response = await http.post(
    Uri.parse('http://localhost:5000/predict'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'text': text,
    }),
  );

  if (response.statusCode == 200) {
    Map<String, dynamic> result = jsonDecode(response.body);
    return result['predicted_emotion'];
  } else {
    throw Exception('Failed to predict emotion');
  }
}
