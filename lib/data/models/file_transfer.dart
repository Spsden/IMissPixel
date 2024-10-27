import 'dart:async';

import '../../services/network/socket/socket_service.dart';

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