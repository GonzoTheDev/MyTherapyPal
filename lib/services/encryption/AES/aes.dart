import 'package:encrypt/encrypt.dart' as encrypt;

class AESEncryption {
  final encrypt.Key key; 
  final encrypt.IV iv;

  // AES encryption requires a key and an IV
  AESEncryption(this.key, this.iv);

  encryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encryptedPrivateKey = encrypter.encrypt(data, iv: iv).base64;
    return encryptedPrivateKey;
  }

  decryptData(String data) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final decrypted = encrypter.decrypt(encrypt.Encrypted.fromBase64(data), iv: iv);
    return decrypted;
  }

}