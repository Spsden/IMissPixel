import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/network/socket/socket_service.dart';

class FileSyncScreen extends StatefulWidget {
  final bool isDeviceA;
  final String? pairCode;

  const FileSyncScreen({
    Key? key,
    required this.isDeviceA,
    required this.pairCode
  }) : super(key: key);

  @override
  State<FileSyncScreen> createState() => _FileSyncScreenState();
}

class _FileSyncScreenState extends State<FileSyncScreen> {
  final List<String> selectedFolders = [];
  WebSocketService? _service;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  Map<String, double> _transferProgress = {};

  @override
  void initState() {
    super.initState();
    // _initializePairCode();
  }

  // void _initializePairCode() {
  //   if (widget.isDeviceA) {
  //     // Generate a random 6-digit code for Device A
  //     final random = Random();
  //     pairCode = List.generate(6, (_) => random.nextInt(10))
  //         .join();
  //     setState(() {});
  //   }
  // }

  Future<void> _validateAndProceed() async {
    // // Validation
    // if (!widget.isDeviceA && selectedFolders.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please select at least one folder to sync')),
    //   );
    //   return;
    // }
    //
    // if (widget.pairCode == null || pairCode!.length != 6) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please enter/generate a valid pair code')),
    //   );
    //   return;
    // }

    // // Request necessary permissions
    // if (!await _requestPermissions()) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Storage permissions are required')),
    //   );
    //   return;
    // }

    // Initialize WebSocket service
    await _initializeService();
  }

  Future<bool> _requestPermissions() async {
    final storage = await Permission.storage.request();
    if (storage.isPermanentlyDenied) {
      // Open app settings if permission is permanently denied
      await openAppSettings();
      return false;
    }
    return storage.isGranted;
  }

  Future<void> _initializeService() async {
    try {
      setState(() => _connectionStatus = ConnectionStatus.connecting);

      _service = WebSocketService(
        pairCode: widget.pairCode!,
        isDeviceA: widget.isDeviceA,
        onError: _handleError,
        onEvent: _handleEvent,
      );

      // Listen to status changes
      _service!.statusStream.listen((status) {
        setState(() => _connectionStatus = status);
        _handleStatusChange(status);
      });

      // Listen to transfer progress
      _service!.transferProgressStream.listen((progress) {
        setState(() => _transferProgress = progress);
      });

      await _service!.initialize();

      // If we're Device B, start syncing selected folders
      if (!widget.isDeviceA && _connectionStatus == ConnectionStatus.connected) {
        _startFolderSync();
      }

    } catch (e) {
      _handleError('Failed to initialize service: $e');
    }
  }

  void _handleStatusChange(ConnectionStatus status) {
    String message;
    switch (status) {
      case ConnectionStatus.connected:
        message = 'Connected successfully!';
        if (!widget.isDeviceA) {
          _startFolderSync();
        }
        break;
      case ConnectionStatus.disconnected:
        message = 'Disconnected from peer';
        break;
      case ConnectionStatus.error:
        message = 'Connection error occurred';
        break;
      default:
        return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _handleError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  }

  void _handleEvent(String event, dynamic data) {
    switch (event) {
      case 'transferComplete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File sync completed: ${data['fileName']}')),
        );
        break;
      case 'incomingTransfer':
      // Could show a notification or progress indicator
        break;
    }
  }

  Future<void> _startFolderSync() async {
    for (final folderPath in selectedFolders) {
      await _syncFolder(folderPath);
    }
  }

  Future<void> _syncFolder(String folderPath) async {
    try {
      final dir = Directory(folderPath);
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          await _syncFile(entity);
        }
      }
    } catch (e) {
      _handleError('Error syncing folder $folderPath: $e');
    }
  }

  Future<void> _syncFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;

      await _service?.sendFile(
        fileName: fileName,
        fileBytes: bytes,
        mimeType: _getMimeType(fileName),
        destinationPath: file.path,
      );
    } catch (e) {
      _handleError('Error syncing file ${file.path}: $e');
    }
  }

  String _getMimeType(String fileName) {
    // Simple MIME type detection based on extension
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _selectFolder() async {
    try {
      // This is a simplified example - you'd want to use a proper folder picker
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        setState(() {
          selectedFolders.add(directory.path);
        });
      }
    } catch (e) {
      _handleError('Error selecting folder: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isDeviceA ? 'Device A (Server)' : 'Device B (Client)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pair Code Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Pair Code',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (widget.isDeviceA)
                      Text(
                        widget.pairCode ?? 'Generating...',
                        style: Theme.of(context).textTheme.headlineMedium,
                      )
                    else
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Enter pair code',
                        ),
                        // onChanged: (value) => setState(() => widget.pairCode = value),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Folder Selection (Device B only)
            if (!widget.isDeviceA) ...[
              Text(
                'Selected Folders',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
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
              ),
              ElevatedButton.icon(
                onPressed: _selectFolder,
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
            Text('Status: $_connectionStatus'),
            const SizedBox(height: 16),

            // Start Button
            ElevatedButton(
              onPressed: _connectionStatus == ConnectionStatus.disconnected
                  ? _validateAndProceed
                  : null,
              child: Text(_connectionStatus == ConnectionStatus.disconnected
                  ? 'Start Sync'
                  : 'Connected'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }
}