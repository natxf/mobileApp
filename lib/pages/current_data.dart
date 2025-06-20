import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class CurrentDataScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream stream;

  const CurrentDataScreen({
    super.key,
    required this.channel,
    required this.stream,
  });

  @override
  _CurrentDataScreenState createState() => _CurrentDataScreenState();
}

class _CurrentDataScreenState extends State<CurrentDataScreen> {
  String temperature = "--";
  String humidity = "--";
  String moisture = "--";
  String brightness = "--";
  String distance = "--";
  bool isLoading = true;

  void fetchSensorData() {
    widget.channel.sink.add("READ_SENSORS");
  }

  @override
  void initState() {
    super.initState();
    fetchSensorData();

    widget.stream.listen((data) {
      try {
        var json = jsonDecode(data);
        setState(() {
          temperature = json['temperature'].toString();
          humidity = json['humidity'].toString();
          moisture = json['moisture'].toString();
          brightness = json['brightness'].toString();
          distance = json['distance'].toString();
          isLoading = false;
        });
      } catch (e) {
        print("Error parsing JSON in CurrentDataScreen: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Błąd danych: $e")),
          );
          setState(() => isLoading = false);
        }
      }
    }, onError: (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Błąd połączenia: $error")),
        );
        setState(() => isLoading = false);
      }
    });
  }

  Widget _buildDataCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required double percentage,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 30, color: color),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "$value $unit",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 15),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "0$unit",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  "${(percentage * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterLevelIndicator() {
    final double waterLevel = double.tryParse(distance) ?? 0;
    final double percentage = (waterLevel / 200).clamp(0.0, 1.0);
    final double invertedPercentage = 1 - percentage;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, size: 30, color: Colors.teal),
                const SizedBox(width: 10),
                const Text(
                  "Poziom wody",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              "$distance cm",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 150 * percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 150 * percentage,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.water_drop,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "${(percentage * 100).toStringAsFixed(0)}% pojemnika",
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double tempValue = double.tryParse(temperature) ?? 0;
    final double humidityValue = double.tryParse(humidity) ?? 0;
    final double moistureValue = double.tryParse(moisture) ?? 0;
    final double brightnessValue = double.tryParse(brightness) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Aktualne dane",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightGreen,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          setState(() => isLoading = true);
          fetchSensorData();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildDataCard(
                icon: Icons.thermostat,
                label: "Temperatura",
                value: temperature,
                unit: "°C",
                color: Colors.red,
                percentage: (tempValue / 40).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildDataCard(
                icon: Icons.cloud,
                label: "Wilgotność powietrza",
                value: humidity,
                unit: "%",
                color: Colors.lightBlue,
                percentage: (humidityValue / 100).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildDataCard(
                icon: Icons.grass,
                label: "Wilgotność gleby",
                value: moisture,
                unit: "%",
                color: Colors.green,
                percentage: (moistureValue / 100).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildDataCard(
                icon: Icons.light_mode,
                label: "Jasność",
                value: brightness,
                unit: "%",
                color: Colors.amber,
                percentage: (brightnessValue / 100).clamp(0.0, 1.0),
              ),
              const SizedBox(height: 16),
              _buildWaterLevelIndicator(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchSensorData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  "Odśwież dane",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}