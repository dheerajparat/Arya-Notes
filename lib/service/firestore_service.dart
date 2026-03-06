import 'package:arya/model/notesmodel.dart';
import 'package:arya/service/encryption_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService();

  String get _userId => _auth.currentUser?.uid ?? '';

  String get _notesCollection => 'users/$_userId/notes';

  Future<void> saveNote(NotesModel note) async {
    try {
      if (_userId.isEmpty) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'User not authenticated.',
        );
      }
      final encryptedPayload = await _buildEncryptedPayload(note);
      await _firestore
          .collection(_notesCollection)
          .doc(note.id)
          .set(encryptedPayload);
    } catch (e) {
      debugPrint('Error saving note to Firestore: $e');
      rethrow;
    }
  }

  Future<void> updateNote(NotesModel note) async {
    try {
      if (_userId.isEmpty) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'User not authenticated.',
        );
      }
      final encryptedPayload = await _buildEncryptedPayload(note);
      await _firestore
          .collection(_notesCollection)
          .doc(note.id)
          .set(encryptedPayload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating note in Firestore: $e');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      if (_userId.isEmpty) {
        throw FirebaseAuthException(
          code: 'not-authenticated',
          message: 'User not authenticated.',
        );
      }
      await _firestore.collection(_notesCollection).doc(noteId).delete();
    } catch (e) {
      debugPrint('Error deleting note from Firestore: $e');
      rethrow;
    }
  }

  Future<List<NotesModel>> getAllNotes() async {
    try {
      if (_userId.isEmpty) {
        return [];
      }
      final snapshot = await _firestore
          .collection(_notesCollection)
          .orderBy('updatedAt', descending: true)
          .get();
      return Future.wait(
        snapshot.docs.map((doc) async {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = data['id'] ?? doc.id;
          return _buildNoteModel(data);
        }),
      );
    } catch (e) {
      debugPrint('Error getting notes from Firestore: $e');
      return [];
    }
  }

  Stream<List<NotesModel>> getNotesStream() {
    try {
      if (_userId.isEmpty) {
        return Stream.value([]);
      }
      return _firestore
          .collection(_notesCollection)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .asyncMap(
            (snapshot) => Future.wait(
              snapshot.docs.map((doc) async {
                final data = doc.data();
                data['id'] = data['id'] ?? doc.id;
                return _buildNoteModel(Map<String, dynamic>.from(data));
              }),
            ),
          );
    } catch (e) {
      debugPrint('Error getting notes stream from Firestore: $e');
      return Stream.value([]);
    }
  }

  Future<Map<String, dynamic>> _buildEncryptedPayload(NotesModel note) async {
    final userId = _userId;
    if (userId.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not authenticated.',
      );
    }

    return {
      'id': note.id,
      'title': await _encryptionService.encryptText(note.title, userId: userId),
      'content': await _encryptionService.encryptText(
        note.content,
        userId: userId,
      ),
      'date': await _encryptionService.encryptText(note.date, userId: userId),
      'time': await _encryptionService.encryptText(note.time, userId: userId),
      'createdAt': note.createdAt.toIso8601String(),
      'updatedAt': note.updatedAt.toIso8601String(),
      'isSyncedWithFirebase': true,
    };
  }

  Future<NotesModel> _buildNoteModel(Map<String, dynamic> data) async {
    final isEncrypted =
        data['isEncrypted'] == true || _hasEncryptedPayload(data);
    if (!isEncrypted) {
      return NotesModel.fromMap(data);
    }

    final userId = _userId;
    if (userId.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User not authenticated.',
      );
    }

    try {
      final decryptedData = Map<String, dynamic>.from(data)
        ..['title'] = await _decryptField(data['title'], userId: userId)
        ..['content'] = await _decryptField(data['content'], userId: userId)
        ..['date'] = await _decryptField(data['date'], userId: userId)
        ..['time'] = await _decryptField(data['time'], userId: userId)
        ..['isSyncedWithFirebase'] = true;

      return NotesModel.fromMap(decryptedData);
    } catch (e) {
      debugPrint('Error decrypting note from Firestore: $e');
      return NotesModel(
        id: (data['id'] ?? '').toString(),
        title: '[Unable to decrypt]',
        content: 'This note cannot be decrypted on this device.',
        date: '',
        time: '',
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
        isSyncedWithFirebase: true,
      );
    }
  }

  Future<String> _decryptField(dynamic value, {required String userId}) async {
    final encryptedText = value as String? ?? '';
    if (encryptedText.isEmpty) {
      return '';
    }

    return _encryptionService.decryptText(encryptedText, userId: userId);
  }

  bool _hasEncryptedPayload(Map<String, dynamic> data) {
    return _isEncryptedField(data['title']) &&
        _isEncryptedField(data['content']) &&
        _isEncryptedField(data['date']) &&
        _isEncryptedField(data['time']);
  }

  bool _isEncryptedField(dynamic value) {
    if (value is! String || value.isEmpty) {
      return false;
    }
    return _encryptionService.looksEncryptedPayload(value);
  }
}
