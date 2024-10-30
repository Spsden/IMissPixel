import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:i_miss_pixel/core/random_name_gen.dart';
import 'package:i_miss_pixel/data/models/client_connection.dart';
import 'package:i_miss_pixel/data/models/server_connection.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:dio/dio.dart';

enum ConnectionStatus { disconnected, connecting, connected, paired, error }

enum TransferStatus { none, preparing, inProgress, completed, failed }

class FileTransfer {
  final String fileName;
  final String mimeType;
  final int totalSize;
  final String? destinationPath;
  int bytesTransferred = 0;
  TransferStatus status = TransferStatus.none;
  final completer = Completer<void>();
  List<int> buffer = [];

  FileTransfer({
    required this.fileName,
    required this.mimeType,
    required this.totalSize,
    this.destinationPath,
  });

  double get progress => totalSize > 0 ? bytesTransferred / totalSize : 0;
}

class WebSocketService {
  static const int PORT = 8888;
  static const int CHUNK_SIZE = 32 * 1024; // 32KB chunks
  static const Duration TIMEOUT = Duration(seconds: 30);
  static const Duration PING_INTERVAL = Duration(seconds: 30);
  static const Duration SERVER_SCAN_INTERVAL = Duration(seconds: 5);

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    sendTimeout: const Duration(seconds: 3),
  ));

  // Server-side properties
  HttpServer? _httpServer;
  final Map<WebSocket, ClientConnection> _connectedClients = {};
  final Map<String, FileTransfer> _activeTransfers = {};

  // Client-side properties
  WebSocket? _clientSocket;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  // Common properties
  final String pairCode;
  final bool isDeviceA;
  final void Function(String message)? onError;
  final void Function(String event, dynamic data)? onEvent;
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _transferProgressController =
      StreamController<Map<String, double>>.broadcast();
  final _serverScanStreamController = StreamController<List<ServerConnection>>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  List<ServerConnection> _servers = [];

  WebSocketService({
    required this.pairCode,
    required this.isDeviceA,
    this.onError,
    this.onEvent,
  });

  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  Stream<Map<String, double>> get transferProgressStream =>
      _transferProgressController.stream;

  Stream<List<ServerConnection>> get serverScanStream =>
      _serverScanStreamController.stream;

  Future<String?> getLocalIpAddress() async {
    try {
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip == null) throw Exception('Failed to get IP address');
      return ip;
    } catch (e) {
      onError?.call('Error getting IP: $e');
      return null;
    }
  }

  Future<void> initialize() async {
    try {
      if (isDeviceA) {
        await _startServer();
      } else {
        await _startClient();
      }
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      onError?.call('Initialization failed: $e');
    }
  }

  Future<void> _startServer() async {
    try {
      _updateStatus(ConnectionStatus.connecting);

      final ipAddress = await getLocalIpAddress();
      print(ipAddress);
      if (ipAddress == null) {
        throw Exception('Failed to get local IP address');
      }

      // Create HTTP server
      _httpServer = await HttpServer.bind(ipAddress, PORT);
      print('WebSocket Server listening on ws://$ipAddress:$PORT');

      // Handle incoming connections
      _httpServer?.listen(
        (HttpRequest request) async {
          if (request.uri.path == '/ping') {
            request.response.statusCode = HttpStatus.forbidden;
            await request.response.close();
            return;
          }

          if (!WebSocketTransformer.isUpgradeRequest(request)) {
            request.response.statusCode = HttpStatus.badRequest;
            await request.response.close();
            return;
          }

          try {
           // final socket = await WebSocketTransformer.upgrade(request);
            _handleServerConnection(request);
          } catch (e) {
            print('Error upgrading to WebSocket: $e');
            request.response.statusCode = HttpStatus.internalServerError;
            await request.response.close();
          }
        },
        onError: (error) {
          print('Server error: $error');
          _updateStatus(ConnectionStatus.error);
          onError?.call('Server error: $error');
        },
        cancelOnError: false,
      );

      _updateStatus(ConnectionStatus.connected);
      onEvent?.call('serverStarted', {'address': 'ws://$ipAddress:$PORT'});
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      onError?.call('Failed to start server: $e');
      rethrow;
    }
  }

  void _handleServerConnection(HttpRequest request) async{
    final socket = await WebSocketTransformer.upgrade(request);
    final clientId = DateTime.now().toString();
    final ipAddress = request.connectionInfo?.remoteAddress.address ??'unknown';
    final String clientName = RandomNameGenerator.generateRandomName();

    final client = ClientConnection(
        id: clientId,
        ipAddress: ipAddress,
        connectedAt: DateTime.now(),
        clientName: clientName);

    _connectedClients[socket] = client;
    onEvent?.call('clientConnected', client);

    socket.listen(
      (dynamic message) {
        if (message is String) {
          _handleMessage(message);
        }
      },
      onDone: () {
        print('client disconnected ${_connectedClients[socket]}');
        final client = _connectedClients[socket];
        onEvent?.call('clientDisconnected', client);
        _connectedClients.remove(socket);
      },
      onError: (error) {
        print('Socket error: $error');
        _connectedClients.remove(socket);
        socket.close();
      },
      cancelOnError: false,
    );

    // Start ping-pong for keep-alive
    Timer.periodic(PING_INTERVAL, (timer) {
      if (!_connectedClients.containsKey(socket)) {
        timer.cancel();
        return;
      }

      try {
        socket.add(jsonEncode({'type': 'ping'}));
      } catch (e) {
        timer.cancel();
        _connectedClients.remove(socket);
        socket.close();
      }
    });

    onEvent?.call('clientConnected', {'id': _connectedClients[socket]});
  }

  Future<void> _startClient() async {
    try {
      _updateStatus(ConnectionStatus.connecting);

      // Try to discover server
      Timer.periodic(SERVER_SCAN_INTERVAL, (timer) async {
        final serverIp = await _discoverServer();
      });

      // if (serverIp == null) {
      //   throw Exception('No server found on the network');
      // }

      //await _connectToServer(serverIp);
      _startKeepAlive();
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
      onError?.call('Failed to start client: $e');
      _scheduleReconnect();
    }
  }

  Future<void> _connectToServer(String serverIp) async {
    try {
      final wsUrl = 'ws://$serverIp:$PORT';
      _clientSocket = await WebSocket.connect(
        wsUrl,
        protocols: ['file-transfer'],
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Connection timed out'),
      );

      _clientSocket!.listen(
        (dynamic message) {
          if (message is String) {
            _handleMessage(message);
          }
        },
        onDone: () {
          print('Disconnected from server');
          _handleDisconnect();
        },
        onError: (error) {
          print('Socket error: $error');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      _updateStatus(ConnectionStatus.connected);
      onEvent?.call('connected', {'address': wsUrl});
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<String?> _discoverServer() async {
    try {
      final info = NetworkInfo();
      final localIp = await info.getWifiIP();
      print(localIp);
      if (localIp == null) return null;

      final subnet = localIp.substring(0, localIp.lastIndexOf('.'));
      final futures = <Future<String?>>[];

      // Scan network in parallel
      for (var i = 1; i < 255; i++) {
        final testIp = '$subnet.$i';
        futures.add(_testServerConnection(testIp));
      }

      final results = await Future.wait(futures);
      final serverIps =
          results.where((ip) => ip != null).cast<String>().toList();
      print(serverIps);
      final List<ServerConnection> allAvailableServers = serverIps
          .map((e) => ServerConnection(ipAddress: e, port: PORT))
          .toList();
      _servers = allAvailableServers;
      _serverScanStreamController.add(_servers);
      if (serverIps != null) {

        onEvent?.call('serversFound', allAvailableServers);
      }
      final serverIp = results.firstWhere(
        (ip) => ip != null,
        orElse: () => null,
      );

      if (serverIp != null) {
        onEvent?.call('serverFound', {'address': serverIp});
      }

      return serverIp;
    } catch (e) {
      onError?.call('Server discovery failed: $e');
      return null;
    }
  }

  Future<String?> _testServerConnection(String ip) async {
    try {
      final response = await dio.get(
        'http://$ip:$PORT/ping',
        options: Options(
          validateStatus: (status) => status == 403,
          sendTimeout: const Duration(seconds: 1),
          receiveTimeout: const Duration(seconds: 1),
        ),
      );

      return response.statusCode == 403 ? ip : null;
    } catch (e) {
      return null;
    }
  }

  void _startKeepAlive() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(PING_INTERVAL, (timer) {
      if (_clientSocket?.readyState != WebSocket.open) {
        timer.cancel();
        return;
      }

      try {
        _sendMessage({'type': 'ping'});
      } catch (e) {
        timer.cancel();
        _handleDisconnect();
      }
    });
  }

  void _handleDisconnect() {
    _clientSocket?.close();
    _clientSocket = null;
    _pingTimer?.cancel();
    _updateStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (_status == ConnectionStatus.disconnected) {
        _startClient();
      }
    });
  }

  Future<void> sendFile({
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    String? destinationPath,
    Function(double)? onProgress,
  }) async {
    if (_status != ConnectionStatus.connected) {
      throw Exception('Not connected to peer');
    }

    final transfer = FileTransfer(
      fileName: fileName,
      mimeType: mimeType,
      totalSize: fileBytes.length,
      destinationPath: destinationPath,
    );

    try {
      _activeTransfers[fileName] = transfer;
      transfer.status = TransferStatus.preparing;

      // Send metadata
      _sendMessage({
        'type': 'fileTransferRequest',
        'fileName': fileName,
        'fileSize': fileBytes.length,
        'mimeType': mimeType,
        'destinationPath': destinationPath,
      });

      // Wait for acceptance
      await _waitForTransferAcceptance(fileName);

      // Send chunks
      transfer.status = TransferStatus.inProgress;
      await _sendFileChunks(transfer, fileBytes, onProgress);

      transfer.status = TransferStatus.completed;
      onEvent?.call('transferComplete', {'fileName': fileName});
    } catch (e) {
      transfer.status = TransferStatus.failed;
      _activeTransfers.remove(fileName);
      onError?.call('File transfer failed: $e');
      rethrow;
    }
  }

  Future<void> _sendFileChunks(
    FileTransfer transfer,
    List<int> fileBytes,
    Function(double)? onProgress,
  ) async {
    var offset = 0;
    while (offset < fileBytes.length) {
      final end = (offset + CHUNK_SIZE) > fileBytes.length
          ? fileBytes.length
          : offset + CHUNK_SIZE;

      final chunk = fileBytes.sublist(offset, end);
      final isLast = end == fileBytes.length;

      _sendMessage({
        'type': 'fileChunk',
        'fileName': transfer.fileName,
        'chunk': base64Encode(chunk),
        'offset': offset,
        'isLast': isLast,
      });

      offset = end;
      transfer.bytesTransferred = offset;

      if (onProgress != null) {
        onProgress(transfer.progress);
      }
      _transferProgressController.add({transfer.fileName: transfer.progress});

      // Add delay to prevent overwhelming the connection
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> _waitForTransferAcceptance(String fileName) async {
    final completer = Completer<void>();
    Timer? timeoutTimer;

    void handleMessage(dynamic message) {
      if (message is Map &&
          message['type'] == 'fileTransferAccepted' &&
          message['fileName'] == fileName) {
        timeoutTimer?.cancel();
        completer.complete();
      }
    }

    // Set up timeout
    timeoutTimer = Timer(TIMEOUT, () {
      if (!completer.isCompleted) {
        completer.completeError(
            TimeoutException('File transfer acceptance timeout'));
      }
    });

    // Add temporary message handler
    onEvent?.call('waitingForAcceptance', {'fileName': fileName});

    return completer.future;
  }

  void _handleIncomingTransfer(Map<String, dynamic> metadata) async {
    final fileName = metadata['fileName'] as String;
    final fileSize = metadata['fileSize'] as int;
    final mimeType = metadata['mimeType'] as String;
    final destinationPath = metadata['destinationPath'] as String?;

    final transfer = FileTransfer(
      fileName: fileName,
      mimeType: mimeType,
      totalSize: fileSize,
      destinationPath: destinationPath,
    );

    _activeTransfers[fileName] = transfer;

    // Notify about incoming transfer
    onEvent?.call('incomingTransfer', metadata);

    // Auto-accept for now (you could add acceptance logic here)
    _sendMessage({
      'type': 'fileTransferAccepted',
      'fileName': fileName,
    });
  }

  void _handleFileChunk(Map<String, dynamic> data) {
    final fileName = data['fileName'] as String;
    final chunk = base64Decode(data['chunk'] as String);
    final offset = data['offset'] as int;
    final isLast = data['isLast'] as bool;

    final transfer = _activeTransfers[fileName];
    if (transfer == null) {
      onError?.call('Received chunk for unknown transfer: $fileName');
      return;
    }

    transfer.buffer.addAll(chunk);
    transfer.bytesTransferred += chunk.length;
    _transferProgressController.add({fileName: transfer.progress});

    if (isLast) {
      _finalizeTransfer(transfer);
    }
  }

  void _finalizeTransfer(FileTransfer transfer) async {
    try {
      if (transfer.destinationPath != null) {
        final file = File(transfer.destinationPath!);
        await file.writeAsBytes(transfer.buffer);
      }

      transfer.status = TransferStatus.completed;
      onEvent?.call('transferComplete',
          {'fileName': transfer.fileName, 'path': transfer.destinationPath});
    } catch (e) {
      transfer.status = TransferStatus.failed;
      onError?.call('Failed to save file: $e');
    } finally {
      _activeTransfers.remove(transfer.fileName);
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    final jsonMessage = jsonEncode(message);
    if (isDeviceA) {
      for (final client in _connectedClients.keys) {
        client.add(jsonMessage);
      }
    } else {
      _clientSocket?.add(jsonMessage);
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;

      switch (data['type']) {
        case 'fileTransferRequest':
          _handleIncomingTransfer(data);
          break;
        case 'fileTransferAccepted':
          onEvent?.call('transferAccepted', data);
          break;
        case 'fileChunk':
          _handleFileChunk(data);
          break;
        case 'ping':
          _sendMessage({'type': 'pong'});
          break;
        case 'pong':
          _sendMessage({'type': 'ping'});
          break;
        case 'suraj':
          _sendMessage({'response' : 'Hello Lord Creator'});
        default:
          print('Unknown message type: ${data['type']}');
      }
    } catch (e) {
      onError?.call('Error handling message: $e');
    }
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void dispose() {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _clientSocket?.close();
    _httpServer?.close();
    _statusController.close();
    _transferProgressController.close();

    for (final client in _connectedClients.keys) {
      client.close();
    }
    _connectedClients.clear();
    _activeTransfers.clear();
  }
  // WebSocketService copyWith({
  //   String? pairCode,
  //   bool? isDeviceA,
  //   void Function(String message)? onError,
  //   void Function(String event, dynamic data)? onEvent,
  // }) {
  //   return WebSocketService(
  //     pairCode: pairCode ?? this.pairCode,
  //     isDeviceA: isDeviceA ?? this.isDeviceA,
  //     onError: onError ?? this.onError,
  //     onEvent: onEvent ?? this.onEvent,
  //   );
  // }

}
