import 'package:flutter/material.dart';
import '../../../../data/models/client_connection.dart';

Widget buildClientsList(List<ClientConnection> clients) {
  if (clients.isEmpty) {
    return const Center(
      child: Text('No clients connected'),
    );
  }

  return ListView.builder(
    shrinkWrap: true,
    itemCount: clients.length,
    itemBuilder: (context, index) {
      final client = clients[index];
      return Card(
        child: ListTile(
          leading: Icon(
            Icons.computer,
            color: client.isActive ? Colors.green : Colors.grey,
          ),
          title: Text('Client ${client.clientName}',style: const TextStyle(fontWeight: FontWeight.bold),),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IP: ${client.ipAddress}'),
              Text('Connected: ${client.connectedAt.toString()}'),
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