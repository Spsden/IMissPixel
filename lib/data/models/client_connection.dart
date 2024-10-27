class ClientConnection {
  final String id;
  final String ipAddress;
  final DateTime connectedAt;
  final bool isActive;

  ClientConnection({
    required this.id,
    required this.ipAddress,
    required this.connectedAt,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ipAddress': ipAddress,
    'connectedAt': connectedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory ClientConnection.fromJson(Map<String, dynamic> json) {
    return ClientConnection(
      id: json['id'],
      ipAddress: json['ipAddress'],
      connectedAt: DateTime.parse(json['connectedAt']),
      isActive: json['isActive'],
    );
  }
}