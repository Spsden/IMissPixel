import 'package:i_miss_pixel/services/network/socket/socket_service.dart';

class WebSocketRepository {
  WebSocketService? _socketService;

  WebSocketService get service {
    if (_socketService == null) {
      throw StateError('WebSocketService not initialized. Call initialize() first.');
    }
    return _socketService!;
  }

  void initialize({
    required String pairCode,
    required bool isDeviceA,
    void Function(String message)? onError,
    void Function(String event, dynamic data)? onEvent,
  }) {
    _socketService = WebSocketService(
      pairCode: pairCode,
      isDeviceA: isDeviceA,
      onError: onError,
      onEvent: onEvent,
    );
  }

  bool get isInitialized => _socketService != null;

  void dispose() {
    _socketService?.dispose();
    _socketService = null;
  }
}