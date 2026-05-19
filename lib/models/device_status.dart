class DeviceStatus {
  final String deviceId; // Tambahan: ID unik perangkat (MAC Address)
  final double gramasi;
  final bool isMotorRunning;
  final double totalVolume;
  final int totalSesi;
  final double rataRata;

  DeviceStatus({
    required this.deviceId, // Wajib diisi
    required this.gramasi,
    required this.isMotorRunning,
    required this.totalVolume,
    required this.totalSesi,
    required this.rataRata,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      // Mengambil 'device_id' yang kini dikirim oleh firmware komersial ESP32
      deviceId: json['device_id'] ?? 'unknown_device', 
      
      gramasi: (json['gramasi'] ?? 0.0).toDouble(),
      isMotorRunning: json['isMotorRunning'] ?? false,
      totalVolume: (json['totalVolume'] ?? 0.0).toDouble(),
      totalSesi: json['totalSesi'] ?? 0,
      rataRata: (json['rataRata'] ?? 0.0).toDouble(),
    );
  }
}