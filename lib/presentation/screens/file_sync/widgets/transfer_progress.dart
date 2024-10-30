import 'package:flutter/material.dart';


Widget buildTransferProgress(Map<String, double> transfers) {
  if (transfers.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Active Transfers',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      ...transfers.entries.map((entry) => Column(
        children: [
          Text(entry.key),
          LinearProgressIndicator(value: entry.value),
          const SizedBox(height: 8),
        ],
      )),
    ],
  );
}