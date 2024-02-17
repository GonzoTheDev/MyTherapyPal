import 'package:crypton/crypton.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/digests/sha256.dart';


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

  generateRSAKeyPair() {
    print("Generating RSA key pair...");
    final rsaKeypair = RSAKeypair.fromRandom();
    
    return (
      publicKey: rsaKeypair.publicKey.toPEM(),
      privateKey: rsaKeypair.privateKey.toPEM(),
    );
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