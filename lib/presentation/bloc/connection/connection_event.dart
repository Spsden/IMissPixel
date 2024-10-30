import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

import '../../../data/models/client_connection.dart';

abstract class ConnectionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializeConnection extends ConnectionEvent {
  final bool isServer;
  final String pairCode;

  InitializeConnection({
    required this.isServer,
    required this.pairCode,
  });

  @override
  List<Object?> get props => [isServer, pairCode];
}

class SendFile extends ConnectionEvent {
  final String filePath;
  final String fileName;
  final String mimeType;
  final String? destinationPath;

  SendFile({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    this.destinationPath,
  });

  @override
  List<Object?> get props => [filePath, fileName, mimeType, destinationPath];
}

class DisconnectRequested extends ConnectionEvent {}

class ClientConnected extends ConnectionEvent {
  final ClientConnection client;

  ClientConnected(this.client);

  @override
  List<Object?> get props => [client];
}

class ClientDisconnected extends ConnectionEvent {
  final String clientId;

  ClientDisconnected(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class TransferProgressUpdated extends ConnectionEvent {
  final Map<String, double> progress;

  TransferProgressUpdated(this.progress);

  @override
  List<Object?> get props => [progress];
}

