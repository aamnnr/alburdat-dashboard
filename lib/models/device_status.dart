class DeviceStatus {
  final double gramasi;
  final bool isMotorRunning;
  final double totalVolume;
  final int totalSesi;
  final double rataRata;

  DeviceStatus({
    required this.gramasi,
    required this.isMotorRunning,
    required this.totalVolume,
    required this.totalSesi,
    required this.rataRata,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      gramasi: (json['gramasi'] ?? 0.0).toDouble(),
      isMotorRunning: json['isMotorRunning'] ?? false,
      totalVolume: (json['totalVolume'] ?? 0.0).toDouble(),
      totalSesi: json['totalSesi'] ?? 0,
      rataRata: (json['rataRata'] ?? 0.0).toDouble(),
    );
  }
}