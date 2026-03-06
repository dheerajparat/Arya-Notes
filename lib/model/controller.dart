import 'package:arya/service/firestore_service.dart';
import 'package:arya/service/local_storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../model/notesmodel.dart';

class Controller extends GetxController {
  final noteslist = <NotesModel>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';
  bool get _isAuthenticated => _userId.trim().isNotEmpty;
  String get _storageUserId => _isAuthenticated ? _userId : 'guest';

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  Future<void> loadNotes({bool syncRemote = true}) async {
    final storageUserId = _storageUserId;

    try {
      isLoading.value = true;
      // Load from local storage first
      final localNotes = await LocalStorageService.getNotes(
        userId: storageUserId,
      );
      noteslist.assignAll(_sortNotes(localNotes));

      // Then sync with Firebase
      if (syncRemote && _isAuthenticated) {
        await syncWithFirebase();
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncWithFirebase() async {
    final storageUserId = _storageUserId;
    if (!_isAuthenticated) {
      return;
    }

    try {
      await _syncPendingNotes();

      final firebaseNotes = await _firestoreService.getAllNotes();
      final pendingLocalNotes = noteslist
          .where((note) => !note.isSyncedWithFirebase)
          .toList();

      final mergedNotes = <NotesModel>[...firebaseNotes];
      for (final localNote in pendingLocalNotes) {
        final alreadyExists = mergedNotes.any(
          (note) => note.id == localNote.id,
        );
        if (!alreadyExists) {
          mergedNotes.add(localNote);
        }
      }

      final sortedNotes = _sortNotes(mergedNotes);
      noteslist.assignAll(sortedNotes);
      await LocalStorageService.saveNotes(sortedNotes, userId: storageUserId);
    } catch (e) {
      debugPrint('Error syncing with Firebase: $e');
    }
  }

  Future<void> refreshNotes() async {
    await loadNotes(syncRemote: true);
  }

  Future<bool> addNote(NotesModel note) async {
    final storageUserId = _storageUserId;

    final now = DateTime.now();
    final normalizedNote = note.copyWith(
      date: DateFormat('yyyy-MM-dd').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      createdAt: now,
      updatedAt: now,
      isSyncedWithFirebase: _isAuthenticated,
    );

    bool syncedWithFirebase = _isAuthenticated;

    try {
      noteslist.add(normalizedNote);
      noteslist.assignAll(_sortNotes(noteslist.toList()));
      await LocalStorageService.saveNotes(noteslist, userId: storageUserId);

      if (_isAuthenticated) {
        try {
          await _firestoreService.saveNote(normalizedNote);
        } catch (e) {
          syncedWithFirebase = false;
          final unsyncedNote = normalizedNote.copyWith(
            isSyncedWithFirebase: false,
          );
          await _replaceNoteLocally(unsyncedNote);
        }
      }
    } catch (e) {
      debugPrint('Error adding note: $e');
      rethrow;
    }

    return syncedWithFirebase;
  }

  Future<bool> updateNote(String id, String title, String content) async {
    final storageUserId = _storageUserId;
    bool syncedWithFirebase = _isAuthenticated;

    try {
      final index = noteslist.indexWhere((note) => note.id == id);
      if (index == -1) {
        throw StateError('Note not found');
      }

      final now = DateTime.now();
      final updatedNote = noteslist[index].copyWith(
        title: title,
        content: content,
        date: DateFormat('yyyy-MM-dd').format(now),
        time: DateFormat('HH:mm:ss').format(now),
        updatedAt: now,
        isSyncedWithFirebase: _isAuthenticated,
      );
      noteslist[index] = updatedNote;
      noteslist.assignAll(_sortNotes(noteslist.toList()));

      await LocalStorageService.saveNotes(noteslist, userId: storageUserId);

      if (_isAuthenticated) {
        try {
          await _firestoreService.updateNote(updatedNote);
        } catch (e) {
          syncedWithFirebase = false;
          final unsyncedNote = updatedNote.copyWith(
            isSyncedWithFirebase: false,
          );
          await _replaceNoteLocally(unsyncedNote);
          debugPrint('Note updated locally, will sync when online: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating note: $e');
      rethrow;
    }

    return syncedWithFirebase;
  }

  Future<bool> deleteNote(String id) async {
    final storageUserId = _storageUserId;
    bool syncedWithFirebase = _isAuthenticated;

    try {
      noteslist.removeWhere((note) => note.id == id);
      await LocalStorageService.saveNotes(noteslist, userId: storageUserId);

      if (_isAuthenticated) {
        try {
          await _firestoreService.deleteNote(id);
        } catch (e) {
          syncedWithFirebase = false;
          debugPrint('Note deleted locally, will sync when online: $e');
        }
      }
    } catch (e) {
      debugPrint('Error deleting note: $e');
      rethrow;
    }

    return syncedWithFirebase;
  }

  Future<void> clearAllNotes() async {
    final storageUserId = _storageUserId;

    try {
      noteslist.clear();
      await LocalStorageService.clearAllNotes(userId: storageUserId);
    } catch (e) {
      debugPrint('Error clearing notes: $e');
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  List<NotesModel> get filteredNotes {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return noteslist.toList();
    }

    return noteslist.where((note) {
      final titleLower = note.title.toLowerCase();
      final contentLower = note.content.toLowerCase();
      return titleLower.contains(query) || contentLower.contains(query);
    }).toList();
  }

  String subtitle(NotesModel note) {
    return '${note.date} • ${note.time}';
  }

  Future<void> _replaceNoteLocally(NotesModel note) async {
    final index = noteslist.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      return;
    }

    noteslist[index] = note;
    noteslist.assignAll(_sortNotes(noteslist.toList()));
    await LocalStorageService.saveNotes(noteslist, userId: _storageUserId);
  }

  Future<void> _syncPendingNotes() async {
    final userId = _userId;
    if (userId.isEmpty) {
      return;
    }

    final pendingNotes = noteslist
        .where((note) => !note.isSyncedWithFirebase)
        .toList();

    if (pendingNotes.isEmpty) {
      return;
    }

    bool didUpdateLocalState = false;

    for (final pendingNote in pendingNotes) {
      try {
        final syncedNote = pendingNote.copyWith(isSyncedWithFirebase: true);
        await _firestoreService.saveNote(syncedNote);

        final index = noteslist.indexWhere((note) => note.id == pendingNote.id);
        if (index != -1) {
          noteslist[index] = syncedNote;
          didUpdateLocalState = true;
        }
      } catch (e) {
        debugPrint('Pending note sync failed (${pendingNote.id}): $e');
      }
    }

    if (didUpdateLocalState) {
      noteslist.assignAll(_sortNotes(noteslist.toList()));
      await LocalStorageService.saveNotes(noteslist, userId: userId);
    }
  }

  List<NotesModel> _sortNotes(List<NotesModel> notes) {
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }
}
