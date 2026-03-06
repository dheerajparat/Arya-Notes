import 'package:arya/model/controller.dart';
import 'package:arya/model/notesmodel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class AddNoteSheet extends StatelessWidget {
  final Controller controller;
  final TextEditingController titleController;
  final TextEditingController contentController;

  const AddNoteSheet({
    super.key,
    required this.controller,
    required this.titleController,
    required this.contentController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Add Note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Content',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
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

                    final syncedWithFirebase = await controller.addNote(
                      NotesModel(
                        id: const Uuid().v4(),
                        title: titleController.text.trim(),
                        content: contentController.text.trim(),
                        date: DateTime.now().toString().split(' ')[0],
                        time: DateTime.now()
                            .toString()
                            .split(' ')[1]
                            .substring(0, 8),
                      ),
                    );

                    titleController.clear();
                    contentController.clear();
                    Get.back();
                    Get.snackbar(
                      syncedWithFirebase ? 'Success' : 'Saved Locally',
                      syncedWithFirebase
                          ? 'Note added successfully'
                          : 'Note saved locally. Firebase sync will retry later.',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2),
                    );
                  } catch (e) {
                    final errorMessage = e.toString();
                    Get.snackbar(
                      'Error',
                      'Failed to save note: $errorMessage',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                    );
                  }
                },
                child: const Text('Add Note'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
