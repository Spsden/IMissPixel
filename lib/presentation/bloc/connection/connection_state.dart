import 'package:equatable/equatable.dart';

import '../../../data/models/client_connection.dart';
import '../../../services/network/socket/socket_service.dart';

enum ConnectionType { server, client }

class WebSocketConnectionState extends Equatable {
  final ConnectionStatus status;
  final ConnectionType type;
  final List<ClientConnection> connectedClients;
  final String? error;
  final Map<String, double> transfers;

  const WebSocketConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.type = ConnectionType.client,
    this.connectedClients = const [],
    this.error,
    this.transfers = const {},
  });

  WebSocketConnectionState copyWith({
    ConnectionStatus? status,
    ConnectionType? type,
    List<ClientConnection>? connectedClients,
    String? error,
    Map<String, double>? transfers,
  }) {
    return WebSocketConnectionState(
      status: status ?? this.status,
      type: type ?? this.type,
      connectedClients: connectedClients ?? this.connectedClients,
      error: error,
      transfers: transfers ?? this.transfers,
    );
  }

  @override
  List<Object?> get props => [
    status,
    type,
    connectedClients,
    error,
    transfers,
  ];
}