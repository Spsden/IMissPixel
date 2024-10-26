import 'package:flutter/material.dart';

class FolderList extends StatelessWidget {
  final List<String> folders;
  final Function(int) onRemove;

  const FolderList({
    super.key,
    required this.folders,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No folders selected'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: folders.length,
      itemBuilder: (context, index) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.folder),
            title: Text(
              folders[index],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onRemove(index),
            ),
          ),
        );
      },
    );
  }
}