import 'dart:convert';

import 'package:cryptography/cryptography.dart';

class EncryptionService {
  static const String _pepperFromEnv = String.fromEnvironment(
    'NOTES_ENCRYPTION_PEPPER',
    defaultValue: '',
  );
  static const String _payloadVersion = 'v1';

  final AesGcm _algorithm = AesGcm.with256bits();
  final Sha256 _hashAlgorithm = Sha256();

  static void validateConfiguration() {
    final pepper = _appPepper;
    if (pepper.length < 16) {
      throw StateError(
        'NOTES_ENCRYPTION_PEPPER must be at least 16 characters.',
      );
    }
  }

  Future<String> encryptText(String plainText, {required String userId}) async {
    final key = await _deriveUserKey(userId);
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
      aad: utf8.encode(userId),
    );

    return _encodePayload(
      nonce: secretBox.nonce,
      cipherText: secretBox.cipherText,
      mac: secretBox.mac.bytes,
    );
  }

  Future<String> decryptText(
    String encryptedPayload, {
    required String userId,
  }) async {
    final parsedPayload = _decodePayload(encryptedPayload);
    final key = await _deriveUserKey(userId);

    final secretBox = SecretBox(
      parsedPayload.cipherText,
      nonce: parsedPayload.nonce,
      mac: Mac(parsedPayload.mac),
    );

    final clearBytes = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
      aad: utf8.encode(userId),
    );

    return utf8.decode(clearBytes);
  }

  bool looksEncryptedPayload(String value) {
    final parts = value.split('.');
    return parts.length == 4 && parts.first == _payloadVersion;
  }

  Future<SecretKey> _deriveUserKey(String userId) async {
    final seed = utf8.encode('$userId|$_appPepper');
    final digest = await _hashAlgorithm.hash(seed);
    return SecretKey(digest.bytes);
  }

  static String get _appPepper {
    if (_pepperFromEnv.isEmpty) {
      throw StateError(
        'Missing NOTES_ENCRYPTION_PEPPER. '
        'Run with --dart-define=NOTES_ENCRYPTION_PEPPER=<your-secret>.',
      );
    }
    return _pepperFromEnv;
  }

  String _encodePayload({
    required List<int> nonce,
    required List<int> cipherText,
    required List<int> mac,
  }) {
    return [
      _payloadVersion,
      base64UrlEncode(nonce),
      base64UrlEncode(cipherText),
      base64UrlEncode(mac),
    ].join('.');
  }

  _ParsedPayload _decodePayload(String payload) {
    if (!looksEncryptedPayload(payload)) {
      throw const FormatException('Invalid encrypted payload');
    }
    final parts = payload.split('.');

    try {
      return _ParsedPayload(
        nonce: base64Url.decode(parts[1]),
        cipherText: base64Url.decode(parts[2]),
        mac: base64Url.decode(parts[3]),
      );
    } catch (_) {
      throw const FormatException('Corrupted encrypted payload');
    }
  }
}

class _ParsedPayload {
  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;

  const _ParsedPayload({
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });
}
