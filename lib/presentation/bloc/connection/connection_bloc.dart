import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';

import '../../../data/models/client_connection.dart';
import '../../../services/network/socket/socket_service.dart';
import 'connection_event.dart';
import 'connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final WebSocketService _socketService;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _transferProgressSubscription;

  ConnectionBloc(this._socketService) : super(const ConnectionState()) {
    on<InitializeConnection>(_onInitializeConnection);
    on<SendFile>(_onSendFile);
    on<DisconnectRequested>(_onDisconnectRequested);
    on<ClientConnected>(_onClientConnected);
    on<ClientDisconnected>(_onClientDisconnected);
    on<TransferProgressUpdated>(_onTransferProgressUpdated);

    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    _statusSubscription = _socketService.statusStream.listen((status) {
      emit(state.copyWith(status: status));
    });

    _transferProgressSubscription =
        _socketService.transferProgressStream.listen((progress) {
          add(TransferProgressUpdated(progress));
        });
  }

  Future<void> _onInitializeConnection(
      InitializeConnection event,
      Emitter<ConnectionState> emit,
      ) async {
    try {
      emit(state.copyWith(
        type: event.isServer ? ConnectionType.server : ConnectionType.client,
        status: ConnectionStatus.connecting,
      ));

      await _socketService.initialize();
    } catch (e) {
      emit(state.copyWith(
        status: ConnectionStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSendFile(
      SendFile event,
      Emitter<ConnectionState> emit,
      ) async {
    try {
      final file = File(event.filePath);
      final bytes = await file.readAsBytes();

      await _socketService.sendFile(
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
      Emitter<ConnectionState> emit,
      ) {
    _socketService.dispose();
    emit(state.copyWith(
      status: ConnectionStatus.disconnected,
      connectedClients: [],
      transfers: {},
    ));
  }

  void _onClientConnected(
      ClientConnected event,
      Emitter<ConnectionState> emit,
      ) {
    final updatedClients = List<ClientConnection>.from(state.connectedClients)
      ..add(event.client);
    emit(state.copyWith(connectedClients: updatedClients));
  }

  void _onClientDisconnected(
      ClientDisconnected event,
      Emitter<ConnectionState> emit,
      ) {
    final updatedClients = state.connectedClients.map((client) {
      if (client.id == event.clientId) {
        return ClientConnection(
          id: client.id,
          ipAddress: client.ipAddress,
          connectedAt: client.connectedAt,
          isActive: false,
        );
      }
      return client;
    }).toList();

    emit(state.copyWith(connectedClients: updatedClients));
  }

  void _onTransferProgressUpdated(
      TransferProgressUpdated event,
      Emitter<ConnectionState> emit,
      ) {
    emit(state.copyWith(transfers: event.progress));
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    _transferProgressSubscription?.cancel();
    _socketService.dispose();
    return super.close();
  }
}

