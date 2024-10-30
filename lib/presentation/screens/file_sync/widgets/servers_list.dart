import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:i_miss_pixel/presentation/bloc/connection/connection_state.dart';
import '../../../../data/models/server_connection.dart';
import '../../../bloc/connection/connection_bloc.dart';

class ServerListWidget extends StatefulWidget {
  @override
  _ServerListWidgetState createState() => _ServerListWidgetState();
}

class _ServerListWidgetState extends State<ServerListWidget> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<ServerConnection> _servers = [];

  @override
  void initState() {
    super.initState();
    context.read<ConnectionBloc>().stream.listen((state) {
      _updateServerList(state.discoveredServers);
        });
  }

  void _updateServerList(List<ServerConnection> newServers) {
    final addedServers = newServers.where((newServer) =>
    !_servers.any((server) => server.ipAddress == newServer.ipAddress)).toList();

    final removedServers = _servers.where((server) =>
    !newServers.any((newServer) => newServer.ipAddress == server.ipAddress)).toList();

    for (var server in addedServers) {
      final index = _servers.length;
      _servers.add(server);
      _listKey.currentState?.insertItem(index);
    }

    for (var server in removedServers) {
      final index = _servers.indexOf(server);
      _listKey.currentState?.removeItem(
        index,
            (context, animation) => _buildItem(server, animation),
      );
      _servers.remove(server);
    }
  }

  Widget _buildItem(ServerConnection server, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          title: Text(
            server.ipAddress,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Port: ${server.port}'),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // Handle delete action
            },
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedList(
        key: _listKey,
        initialItemCount: _servers.length,
        itemBuilder: (context, index, animation) {
          return _buildItem(_servers[index], animation);
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
