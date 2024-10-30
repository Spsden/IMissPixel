class ClientConnection {
  final String id;
  final String ipAddress;
  final DateTime connectedAt;
  final bool isActive;
  final String clientName;

  ClientConnection({
    required this.id,
    required this.ipAddress,
    required this.connectedAt,
    this.isActive = true,
    required this.clientName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ipAddress': ipAddress,
    'connectedAt': connectedAt.toIso8601String(),
    'isActive': isActive,
    'clientName':clientName
  };

  factory ClientConnection.fromJson(Map<String, dynamic> json) {
    return ClientConnection(
      id: json['id'],
      ipAddress: json['ipAddress'],
      connectedAt: DateTime.parse(json['connectedAt']),
      isActive: json['isActive'],
      clientName: json['clientName']
    );
  }
}