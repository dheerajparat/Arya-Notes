import 'dart:convert';
import 'package:arya/model/notesmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocalStorageService {
  static const String _notesKeyPrefix = 'notes_list';

  static String _notesKeyForUser(String userId) {
    final normalizedUserId = userId.trim().isEmpty ? 'guest' : userId.trim();
    return '${_notesKeyPrefix}_$normalizedUserId';
  }

  static Future<List<NotesModel>> getNotes({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getStringList(_notesKeyForUser(userId)) ?? [];
      return notesJson
          .map((note) => NotesModel.fromMap(jsonDecode(note)))
          .toList();
    } catch (e) {
      debugPrint('Error getting notes from local storage: $e');
      return [];
    }
  }

  static Future<void> saveNotes(
    List<NotesModel> notes, {
    required String userId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes.map((note) => jsonEncode(note.toMap())).toList();
      await prefs.setStringList(_notesKeyForUser(userId), notesJson);
    } catch (e) {
      debugPrint('Error saving notes to local storage: $e');
    }
  }

  static Future<void> addNote(NotesModel note, {required String userId}) async {
    try {
      final notes = await getNotes(userId: userId);
      notes.add(note);
      await saveNotes(notes, userId: userId);
    } catch (e) {
      debugPrint('Error adding note to local storage: $e');
    }
  }

  static Future<void> updateNote(
    NotesModel note, {
    required String userId,
  }) async {
    try {
      final notes = await getNotes(userId: userId);
      final index = notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        notes[index] = note;
        await saveNotes(notes, userId: userId);
      }
    } catch (e) {
      debugPrint('Error updating note in local storage: $e');
    }
  }

  static Future<void> deleteNote(String id, {required String userId}) async {
    try {
      final notes = await getNotes(userId: userId);
      notes.removeWhere((note) => note.id == id);
      await saveNotes(notes, userId: userId);
    } catch (e) {
      debugPrint('Error deleting note from local storage: $e');
    }
  }

  static Future<void> clearAllNotes({required String userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notesKeyForUser(userId));
    } catch (e) {
      debugPrint('Error clearing notes from local storage: $e');
    }
  }
}
