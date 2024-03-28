import 'package:crypton/crypton.dart';
import 'package:my_therapy_pal/services/encryption/RSA/rsa_keypair.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:http/http.dart' as http;


class RSAEncryption {

  Uint8List generateRandomSalt([int length = 16]) {
    final Random random = Random.secure();
    var values = List<int>.generate(length, (i) => random.nextInt(256));
    return Uint8List.fromList(values);
  }

  Uint8List deriveKey(String password, Uint8List salt, {int iterations = 10000, int derivedKeyLength = 32}) {
    
    // Create a PBKDF2 instance with HMAC-SHA256
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64))
      ..init(Pbkdf2Parameters(salt, iterations, derivedKeyLength));

    // Convert password to bytes
    final passwordBytes = utf8.encode(password);
    
    // Derive the key
    final result = pbkdf2.process(passwordBytes);

    return result;
  }

  Future<RSAKeyPair> generateRSAKeyPair() async {
    try {
      // Specify the URL of your API endpoint
      final url = Uri.parse('https://pleased-perch-polite.ngrok-free.app/generate_rsa_keys');

      // Make the HTTP POST request
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      // Check if the response is successful
      if (response.statusCode == 200) {
        // Decode the JSON response
        final jsonResponse = jsonDecode(response.body);
        final publicKey = jsonResponse['publicKey'];
        final privateKey = jsonResponse['privateKey'];

        // Return the RSAKeyPair with the keys obtained from the response
        return RSAKeyPair(publicKey: publicKey, privateKey: privateKey);
      } else {
        print('Error: Failed to load response, status code: ${response.statusCode}');
        return Future.error('Server error: Could not generate RSA keys.');
      }
    } catch (e, stackTrace) {
      // Handle errors from the HTTP request
      print('Error: Failed to make a request: $e');
      print('Stack trace: $stackTrace');
      return Future.error('Network error: Failed to generate RSA keys.');
    }
  }

  RSAPrivateKey parseRSAfromPEM(String? key) {
    return RSAPrivateKey.fromPEM(key!);
  }

  String encrypt({
    required String key,
    required String message,
  }) {
    final rsaPublicKey = RSAPublicKey.fromPEM(key);
    final result = rsaPublicKey.encrypt(message);
    return result;
  }

  String decrypt({
    required String? key,
    required String message,
  }) {
    final rsaPrivateKey = RSAPrivateKey.fromPEM(key!);
    final result = rsaPrivateKey.decrypt(message);
    return result;
  }
}