import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:i_miss_pixel/presentation/bloc/connection/connection_bloc.dart';
import 'package:i_miss_pixel/presentation/bloc/connection/connection_state.dart' as connection_state;
import 'package:i_miss_pixel/presentation/screens/file_sync/widgets/connected_clients.dart';
import 'package:i_miss_pixel/presentation/screens/file_sync/widgets/servers_list.dart';
import '../../../services/network/socket/socket_service.dart';
import '../../bloc/connection/connection_event.dart';

class FileSyncScreen extends StatefulWidget {
  final bool isDeviceA;
  final String? pairCode;

  const FileSyncScreen({Key? key, required this.isDeviceA, required this.pairCode}) : super(key: key);

  @override
  State<FileSyncScreen> createState() => _FileSyncScreenState();
}

class _FileSyncScreenState extends State<FileSyncScreen> {
  final List<String> selectedFolders = [];
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Map<String, double> _transferProgress = {};

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  void _initializeConnection() {
    context.read<ConnectionBloc>().add(
      InitializeConnection(
        isServer: widget.isDeviceA,
        pairCode: widget.pairCode.toString(),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.isDeviceA ? 'Receiver' : 'Sender',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.pairCode ?? 'Generating...',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: BlocConsumer<ConnectionBloc, connection_state.WebSocketConnectionState>(
        listener: (context, state) {
          if (state.error?.isNotEmpty ?? false) {
            _showError(state.error!);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        if (widget.isDeviceA) ...[
                          Text(
                            'Connected Clients',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // SizedBox(
                          //   height: 300,
                          //   child:  buildClientsList(state.connectedClients),
                          // ),
                           buildClientsList(state.connectedClients),
                          const SizedBox(height: 24),
                        ],
                        if (!widget.isDeviceA) ...[
                          Text(
                            'All Servers',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ServerListWidget(),
                          const SizedBox(height: 24),
                        ],
                        // Folder Selection (Device B only)
                        if (!widget.isDeviceA) ...[
                          Text(
                            'Selected Folders',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: selectedFolders.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(selectedFolders[index]),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    setState(() {
                                      selectedFolders.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            onPressed: () => {},
                            icon: const Icon(Icons.create_new_folder),
                            label: const Text('Add Folder'),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Progress Section
                        if (_transferProgress.isNotEmpty) ...[
                          const Text('Transfer Progress:'),
                          const SizedBox(height: 8),
                          ...(_transferProgress.entries.map((entry) => Column(
                            children: [
                              Text(entry.key),
                              LinearProgressIndicator(value: entry.value),
                              const SizedBox(height: 8),
                            ],
                          ))),
                        ],
                        // Connection Status
                        Text('Status: ${state.status}'),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Start Button
                ElevatedButton(
                  onPressed: _connectionStatus == ConnectionStatus.disconnected
                      ? () {
                    final bloc = context.read<ConnectionBloc>();
                    bloc.add(
                      InitializeConnection(
                        isServer: widget.isDeviceA,
                        pairCode: widget.pairCode.toString(),
                      ),
                    );
                  }
                      : null,
                  child: Text(_connectionStatus == ConnectionStatus.disconnected
                      ? 'Start Sync'
                      : 'Connected'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
