import 'package:arya/model/controller.dart';
import 'package:arya/model/notesmodel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NoteDetailPage extends StatefulWidget {
  final NotesModel note;

  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late Controller controller;
  bool isEditMode = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
    controller = Get.find<Controller>();
  }

  NotesModel get _currentNote {
    final index = controller.noteslist.indexWhere(
      (n) => n.id == widget.note.id,
    );
    if (index == -1) {
      return widget.note;
    }
    return controller.noteslist[index];
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (titleController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Title cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (contentController.text.trim().isEmpty) {
      Get.snackbar(
        'Validation Error',
        'Content cannot be empty',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final syncedWithFirebase = await controller.updateNote(
        widget.note.id,
        titleController.text.trim(),
        contentController.text.trim(),
      );

      Get.snackbar(
        syncedWithFirebase ? 'Success' : 'Saved Locally',
        syncedWithFirebase
            ? 'Note updated successfully'
            : 'Note updated locally. Firebase sync will retry later.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      setState(() => isEditMode = false);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update note',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteNote() async {
    Get.defaultDialog(
      title: 'Delete Note',
      middleText: 'Are you sure you want to delete this note?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        try {
          final syncedWithFirebase = await controller.deleteNote(
            widget.note.id,
          );
          Get.snackbar(
            syncedWithFirebase ? 'Deleted' : 'Deleted Locally',
            syncedWithFirebase
                ? 'Note deleted successfully'
                : 'Note removed locally. It may still appear in Firebase.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
          Get.back();
          Get.back();
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
    final activeNote = _currentNote;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Note Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        actions: [
          if (!isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditMode = true),
              tooltip: 'Edit Note',
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                isEditMode = false;
                titleController.text = activeNote.title;
                contentController.text = activeNote.content;
              }),
              tooltip: 'Cancel',
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteNote,
            tooltip: 'Delete Note',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            if (!isEditMode)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeNote.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeNote.date,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        activeNote.time,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    activeNote.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: contentController,
                    maxLines: 10,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Content',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.inversePrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
