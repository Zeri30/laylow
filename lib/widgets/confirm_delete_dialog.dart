import 'package:flutter/material.dart';

/// Shows a delete confirmation dialog; resolves to whether the user
/// confirmed.
Future<bool> confirmDeleteEntry(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete entry?'),
      content: const Text(
        "This journal entry and its mood rating will be permanently deleted.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
