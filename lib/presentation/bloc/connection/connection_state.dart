import 'package:equatable/equatable.dart';

import '../../../data/models/client_connection.dart';
import '../../../data/models/server_connection.dart';
import '../../../services/network/socket/socket_service.dart';

enum ConnectionType { server, client }

class WebSocketConnectionState extends Equatable {
  final ConnectionStatus status;
  final ConnectionType type;
  final List<ClientConnection> connectedClients;
  final ServerConnection? serverConnected;
  final String? error;
  final Map<String, double> transfers;
  final String? lastMessage;
  final bool isLoading;
  final List<ServerConnection> discoveredServers;
  final ServerStatus serverStatus;

  const WebSocketConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.type = ConnectionType.client,
    this.connectedClients = const [],
    this.serverConnected,
    this.error,
    this.transfers = const {},
    this.lastMessage,
    this.isLoading = false,
    this.discoveredServers = const [],
    this.serverStatus=ServerStatus.stopped
  });

  WebSocketConnectionState copyWith({
    ConnectionStatus? status,
    ConnectionType? type,
    List<ClientConnection>? connectedClients,
    ServerConnection? serverConnected,
    String? error,
    Map<String, double>? transfers,
    String? lastMessage,
    bool? isLoading,
    List<ServerConnection>? discoveredServers,
    ServerStatus? serverStatus,
  }) {
    return WebSocketConnectionState(
      status: status ?? this.status,
      type: type ?? this.type,
      connectedClients: connectedClients ?? this.connectedClients,
      serverConnected: serverConnected ?? this.serverConnected,
      error: error,
      transfers: transfers ?? this.transfers,
      lastMessage: lastMessage ?? this.lastMessage,
      isLoading: isLoading ?? this.isLoading,
      discoveredServers: discoveredServers ?? this.discoveredServers,
      serverStatus: serverStatus ?? this.serverStatus,
    );
  }

  @override
  List<Object?> get props => [
    status,
    type,
    connectedClients,
    serverConnected,
    error,
    transfers,
    lastMessage,
    isLoading,
    discoveredServers,
    serverStatus
  ];
}
