import 'package:flutter/material.dart';


import '../../../../data/models/server_connection.dart';

Widget buildServerList(List<ServerConnection> servers) {
  return Expanded(
    child: ListView.builder(
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final server = servers[index];
        return ListTile(
          title: Text(server.ipAddress),
          subtitle: Text('Port: ${server.port}'),
        );
      },
    ),
  );
}
