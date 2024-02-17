import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'dart:math';
import 'package:crypton/crypton.dart' as crypton;
import 'package:crypto/crypto.dart';


class AESKeyEncryptionService {

  // Generate a random AES key
  Uint8List generateAESKey(int length) { // Length in bytes, AES commonly uses 16, 24, or 32 bytes keys
    var rng = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => rng.nextInt(256)));
  }

  // Encrypt the AES key with the users RSA public key
  Uint8List encryptAESKey(Uint8List aesKey, RSAPublicKey publicKey) {
    var encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey)); // true for encryption

    return encryptor.process(aesKey);
  }

  // Decrypt the AES key with the users RSA private key
  Uint8List decryptAESKey(Uint8List encryptedAESKey, crypton.RSAPrivateKey privateKey) {
    var decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey as PrivateKey)); // false for decryption

    return decryptor.process(encryptedAESKey);
  }

  // Generate a random IV from the document ID
  Uint8List generateIVFromDocId(String docId) {
    var bytes = utf8.encode(docId); // Original document ID as bytes
    var hash = sha256.convert(bytes); // Use SHA-256 hash of the document ID
    return Uint8List.fromList(hash.bytes.sublist(0, 16)); // Take first 16 bytes of the hash
  }

}