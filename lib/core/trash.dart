// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
//
// import '../../../data/models/client_connection.dart';
// import '../../../services/network/socket/socket_service.dart';
// import '../bloc/connection_bloc.dart';
// import '../bloc/connection_event.dart';
// import '../bloc/connection_state.dart' as connection_state;
//
// class FileSyncScreen extends StatefulWidget {
//   final bool isDeviceA;
//   final String? pairCode;
//
//   const FileSyncScreen({
//     Key? key,
//     required this.isDeviceA,
//     required this.pairCode,
//   }) : super(key: key);
//
//   @override
//   State<FileSyncScreen> createState() => _FileSyncScreenState();
// }
//
// class _FileSyncScreenState extends State<FileSyncScreen> {
//   final List<String> selectedFolders = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeConnection();
//   }
//
//   void _initializeConnection() {
//     context.read<ConnectionBloc>().add(
//       InitializeConnection(isServer: widget.isDeviceA),
//     );
//   }
//
//   Future<bool> _requestPermissions() async {
//     final storage = await Permission.storage.request();
//     if (storage.isPermanentlyDenied) {
//       await openAppSettings();
//       return false;
//     }
//     return storage.isGranted;
//   }
//
//   Future<void> _selectFolder() async {
//     try {
//       final directory = await getExternalStorageDirectory();
//       if (directory != null) {
//         setState(() {
//           selectedFolders.add(directory.path);
//         });
//       }
//     } catch (e) {
//       _showError('Error selecting folder: $e');
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   Widget _buildClientsList(List<ClientConnection> clients) {
//     if (clients.isEmpty) {
//       return const Center(
//         child: Text('No clients connected'),
//       );
//     }
//
//     return ListView.builder(
//       shrinkWrap: true,
//       itemCount: clients.length,
//       itemBuilder: (context, index) {
//         final client = clients[index];
//         return Card(
//           child: ListTile(
//             leading: Icon(
//               Icons.computer,
//               color: client.isActive ? Colors.green : Colors.grey,
//             ),
//             title: Text('Client ${client.id}'),
//             subtitle: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('IP: ${client.ipAddress}'),
//                 Text('Connected: ${client.connectedAt.toString()}'),
//               ],
//             ),
//             trailing: client.isActive
//                 ? const Icon(Icons.check_circle, color: Colors.green)
//                 : const Icon(Icons.error_outline, color: Colors.grey),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildTransferProgress(Map<String, double> transfers) {
//     if (transfers.isEmpty) return const SizedBox.shrink();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Active Transfers',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         ...transfers.entries.map((entry) => Column(
//           children: [
//             Text(entry.key),
//             LinearProgressIndicator(value: entry.value),
//             const SizedBox(height: 8),
//           ],
//         )),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.isDeviceA ? 'Device A (Server)' : 'Device B (Client)'),
//       ),
//       body: BlocConsumer<ConnectionBloc, connection_state.ConnectionState>(
//         listener: (context, state) {
//           if (state.error?.isNotEmpty ?? false) {
//             _showError(state.error!);
//           }
//         },
//         builder: (context, state) {
//           return Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Pair Code Section
//                 Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       children: [
//                         Text(
//                           'Pair Code',
//                           style: Theme.of(context).textTheme.headlineSmall,
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           widget.pairCode ?? 'No code available',
//                           style: Theme.of(context).textTheme.headlineMedium,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Connected Clients Section (Only for Device A)
//                 if (widget.isDeviceA) ...[
//                   Text(
//                     'Connected Clients',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                   const SizedBox(height: 8),
//                   _buildClientsList(state.connectedClients),
//                   const SizedBox(height: 16),
//                 ],
//
//                 // Folder Selection (Device B only)
//                 if (!widget.isDeviceA) ...[
//                   Text(
//                     'Selected Folders',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                   const SizedBox(height: 8),
//                   Expanded(
//                     child: ListView.builder(
//                       itemCount: selectedFolders.length,
//                       itemBuilder: (context, index) {
//                         return ListTile(
//                           title: Text(selectedFolders[index]),
//                           trailing: IconButton(
//                             icon: const Icon(Icons.delete),
//                             onPressed: () {
//                               setState(() {
//                                 selectedFolders.removeAt(index);
//                               });
//                             },
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   ElevatedButton.icon(
//                     onPressed: _selectFolder,
//                     icon: const Icon(Icons.create_new_folder),
//                     label: const Text('Add Folder'),
//                   ),
//                 ],
//
//                 const SizedBox(height: 16),
//
//                 // Transfer Progress Section
//                 _buildTransferProgress(state.transfers),
//
//                 const SizedBox(height: 16),
//
//                 // Connection Status
//                 Text('Status: ${state.status}'),
//
//                 const SizedBox(height: 16),
//
//                 // Action Button
//                 ElevatedButton(
//                   onPressed: state.status == ConnectionStatus.disconnected
//                       ? () async {
//                     if (await _requestPermissions()) {
//                       _initializeConnection();
//                     }
//                   }
//                       : () {
//                     context.read<ConnectionBloc>().add(DisconnectRequested());
//                   },
//                   child: Text(
//                     state.status == ConnectionStatus.disconnected
//                         ? 'Start Sync'
//                         : 'Disconnect',
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
// }