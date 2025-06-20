import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'dart:convert';

class ESPControlPage extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream<dynamic> stream;

  const ESPControlPage({super.key, required this.channel, required this.stream});

  @override
  _ESPControlPageState createState() => _ESPControlPageState();
}

class _ESPControlPageState extends State<ESPControlPage> {
  bool isManualMode = false;
  bool isLoading = true;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();

    subscription = widget.stream.listen((message) {
      handleWebSocketMessage(message);
    });

    widget.channel.sink.add("DESIRED_ENVIRONMENT");
  }

  void handleWebSocketMessage(String message) {
    try {
      final data = jsonDecode(message);

      if (data is Map && data.containsKey('mode')) {
        final mode = data['mode'];
        setState(() {
          isManualMode = (mode == "MANUAL");
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error decoding WebSocket message: $e");
    }
  }

  void toggleMode(bool value) {
    setState(() {
      isManualMode = value;
    });

    widget.channel.sink.add(value ? "MANUAL" : "AUTO");

    if (value) {
      Workmanager().registerPeriodicTask(
        "envTask",
        "envCheckTask",
        frequency: const Duration(minutes: 15),
      );
    } else {
      Workmanager().cancelAll();
    }
  }

  void waterPlant() {
    if (isManualMode) {
      widget.channel.sink.add("WATER");
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sterowanie ESP32",
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
      body: Center(
        child: isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              "Oczekiwanie na dane z ESP32...",
              style: TextStyle(fontSize: 16),
            ),
          ],
        )
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 20.0, horizontal: 16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Wybierz tryb pracy",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text(
                          "Tryb manualny",
                          style: TextStyle(fontSize: 18),
                        ),
                        value: isManualMode,
                        activeColor: Colors.green,
                        onChanged: toggleMode,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: isManualMode ? waterPlant : null,
                icon: const Icon(Icons.opacity),
                label: const Text(
                  "Podlej roślinę",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  isManualMode ? Colors.green : Colors.grey,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
