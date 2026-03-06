import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../service/firebase_service.dart';
import '../model/controller.dart';
import '../widgets/add_note_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late TextEditingController _searchController;
  late Controller controller;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _searchController = TextEditingController();
    controller = Get.isRegistered<Controller>()
        ? Get.find<Controller>()
        : Get.put(Controller());
    controller.loadNotes();
  }

  @override
  void dispose() {
    try {
      _titleController.dispose();
      _contentController.dispose();
      _searchController.dispose();
    } catch (e) {
      debugPrint('Error disposing controllers: $e');
    }
    super.dispose();
  }

  void _clearControllers() {
    _titleController.clear();
    _contentController.clear();
  }

  void _showAddNoteSheet() {
    _clearControllers();
    try {
      Get.bottomSheet(
        AddNoteSheet(
          controller: controller,
          titleController: _titleController,
          contentController: _contentController,
        ),
        isScrollControlled: true,
      );
    } catch (e) {
      debugPrint('Error showing add note sheet: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _authService.signOut();
      if (Get.isRegistered<Controller>()) {
        Get.delete<Controller>(force: true);
      }
      Get.offAllNamed('/');
    } catch (e) {
      Get.snackbar(
        'Logout Failed',
        'Unable to logout right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _confirmDelete(String id) async {
    Get.defaultDialog(
      title: 'Delete Note',
      middleText: 'Are you sure you want to delete this note?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          final syncedWithFirebase = await controller.deleteNote(id);
          Get.back();
          if (!mounted) {
            return;
          }
          Get.snackbar(
            syncedWithFirebase ? 'Deleted' : 'Deleted Locally',
            syncedWithFirebase
                ? 'Note deleted successfully'
                : 'Note removed locally. It may still appear in Firebase.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            'Error',
            'Failed to delete note',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        title: const Text('Arya-Notes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refreshNotes,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                controller.updateSearchQuery(value);
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          controller.updateSearchQuery('');
                          FocusScope.of(context).unfocus();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final visibleNotes = controller.filteredNotes;
              final hasQuery = controller.searchQuery.value.trim().isNotEmpty;

              if (controller.isLoading.value && controller.noteslist.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (visibleNotes.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refreshNotes,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                      Icon(
                        hasQuery ? Icons.search_off : Icons.note_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          hasQuery ? 'No matching notes' : 'No notes yet',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          hasQuery
                              ? 'Try a different search term'
                              : 'Tap + to create your first note',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshNotes,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  itemCount: visibleNotes.length,
                  itemBuilder: (context, index) {
                    final note = visibleNotes[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              note.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.subtitle(note),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            if (!note.isSyncedWithFirebase)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Saved locally (sync pending)',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: Colors.orange),
                                ),
                              ),
                          ],
                        ),
                        onTap: () =>
                            Get.toNamed('/note-detail', arguments: note),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(note.id),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        onPressed: _showAddNoteSheet,
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
