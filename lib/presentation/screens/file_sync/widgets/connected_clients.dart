import 'package:flutter/material.dart';
import '../../../../data/models/client_connection.dart';

Widget buildClientsList(List<ClientConnection> clients) {
  if (clients.isEmpty) {
    return const Center(
      child: Text(
        'No clients connected',
        style: TextStyle(color: Colors.white70), // Subtle color for dark theme
      ),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: clients.length,
    itemBuilder: (context, index) {
      final client = clients[index];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Added margin for spacing
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Rounded corners
        ),
        elevation: 4, // Subtle elevation for depth
        color: Colors.grey[850], // Dark background for the card
        child: ListTile(
          leading: Icon(
            Icons.computer,
            color: client.isActive ? Colors.green : Colors.grey,
          ),
          title: Text(
            'Client ${client.clientName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // Ensure title is visible
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IP: ${client.ipAddress}',
                style: TextStyle(color: Colors.white70), // Lighter color for contrast
              ),
              Text(
                'Connected: ${client.connectedAt.toString()}',
                style: TextStyle(color: Colors.white70), // Lighter color for contrast
              ),
            ],
          ),
          trailing: client.isActive
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.error_outline, color: Colors.grey),
        ),
      );
    },
  );
}
