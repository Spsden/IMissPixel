import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:i_miss_pixel/data/models/server_connection.dart';
import 'package:i_miss_pixel/services/network/socket/socket_service_repo.dart';

import '../../../data/models/client_connection.dart';
import '../../../services/network/socket/socket_service.dart';
import 'connection_event.dart';
import 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, WebSocketConnectionState> {
  WebSocketRepository repository;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _transferProgressSubscription;

  ConnectionBloc(this.repository) : super(const WebSocketConnectionState()) {
    on<InitializeConnection>(_onInitializeConnection);
    on<SendFile>(_onSendFile);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ClientConnected>(_onClientConnected);
    on<ClientDisconnected>(_onClientDisconnected);
    on<TransferProgressUpdated>(_onTransferProgressUpdated);
    on<ServerDiscovered>(_onServerDiscovered);
  }

  void handleWebSocketEvent(String event, dynamic data) {
    switch (event) {
      case 'clientConnected':
        if (data is ClientConnection) {
          add(ClientConnected(data));
        }
        break;
      case 'clientDisconnected':
        if (data is ClientConnection) {
          add(ClientDisconnected(data));
        }
        break;
      case 'serversFound':
        if(data is List<ServerConnection>){
          add(ServerDiscovered(data));
        }


      // Add more event handlers as needed
    }
  }

  void _setupSubscriptions() {
    _statusSubscription?.cancel();  // Cancel any existing subscriptions
    _transferProgressSubscription?.cancel();

    _statusSubscription = repository.service.statusStream.listen((status) {
      emit(state.copyWith(status: status));
    });

    _transferProgressSubscription =
        repository.service.transferProgressStream.listen((progress) {
          add(TransferProgressUpdated(progress));
        });
  }

  Future<void> _onInitializeConnection(
    InitializeConnection event,
    Emitter<WebSocketConnectionState> emit,
  ) async {
    try {
      // if(!repository.isInitialized){
      //   throw StateError("Pixel::Service not initialized");
      // }
      emit(state.copyWith(
        type: event.isServer ? ConnectionType.server : ConnectionType.client,
        status: ConnectionStatus.connecting,
      ));
      if (!repository.isInitialized) {
        repository.initialize(
          pairCode: event.pairCode,
          isDeviceA: event.isServer,
          onEvent: handleWebSocketEvent,
        );
      }
       _setupSubscriptions();
      await repository.service.initialize();
    } catch (e) {
      emit(state.copyWith(
        status: ConnectionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSendFile(
    SendFile event,
    Emitter<WebSocketConnectionState> emit,
  ) async {
    try {
      final file = File(event.filePath);
      final bytes = await file.readAsBytes();

      await repository.service.sendFile(
        fileName: event.fileName,
        fileBytes: bytes,
        mimeType: event.mimeType,
        destinationPath: event.destinationPath,
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onDisconnectRequested(
    DisconnectRequested event,
    Emitter<WebSocketConnectionState> emit,
  ) {
    repository.service.dispose();
    emit(state.copyWith(
      status: ConnectionStatus.disconnected,
      connectedClients: [],
      transfers: {},
    ));
  }

  void _onClientConnected(
    ClientConnected event,
    Emitter<WebSocketConnectionState> emit,
  ) {
    final updatedClients = List<ClientConnection>.from(state.connectedClients)
      ..add(event.client);
    emit(state.copyWith(connectedClients: updatedClients));
  }

  void _onClientDisconnected(
    ClientDisconnected event,
    Emitter<WebSocketConnectionState> emit,
  ) {
    final updatedClients = state.connectedClients.map((client) {
      if (client == event.client) {
        return ClientConnection(
          id: client.id,
          ipAddress: client.ipAddress,
          connectedAt: client.connectedAt,
          isActive: false,
          clientName: client.clientName
        );
      }
      return client;
    }).toList();
    print(updatedClients);

    emit(state.copyWith(connectedClients: updatedClients));
  }

  void _onTransferProgressUpdated(
    TransferProgressUpdated event,
    Emitter<WebSocketConnectionState> emit,
  ) {
    emit(state.copyWith(transfers: event.progress));
  }

  void _onServerDiscovered(
      ServerDiscovered event,
      Emitter<WebSocketConnectionState> emit,
      ){
    final updatedSeversList = List<ServerConnection>.from(state.discoveredServers)
        ..addAll(event.servers);
    emit(state.copyWith(discoveredServers: updatedSeversList));

  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _transferProgressSubscription?.cancel();
    repository.dispose();
    return super.close();
  }
}
