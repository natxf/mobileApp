class SensorsData{
  final DateTime createdAt;
  final double temperature;
  final double brightness;
  final double humidity;
  final double moisture;
  final double waterLevel;


  SensorsData({
    required this.createdAt,
    required this.temperature,
    required this.brightness,
    required this.humidity,
    required this.moisture,
    required this.waterLevel,
  });

  factory SensorsData.fromJson(Map<String, dynamic> json){
    return SensorsData(
        createdAt: DateTime.parse(json['created_at']),
        temperature: (json['temperature'] ?? 0).toDouble(),
        brightness: (json['brightness'] ?? 0).toDouble(),
        humidity: (json['humidity'] ?? 0).toDouble(),
        moisture: (json['moisture'] ?? 0).toDouble(),
        waterLevel: (json['water_level'] ?? 0).toDouble());
  }

  Map<String, dynamic> toJson() => {
    'created_at': createdAt.toIso8601String(),
    'temperature': temperature,
    'brightness': brightness,
    'humidity': humidity,
    'moisture': moisture,
    'water_level': waterLevel,
  };

}