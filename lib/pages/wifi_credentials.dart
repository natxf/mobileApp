import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

class WiFiCredentialsScreen extends StatefulWidget {
  final BluetoothCharacteristic characteristic;

  const WiFiCredentialsScreen({super.key, required this.characteristic});

  @override
  State<WiFiCredentialsScreen> createState() => _WiFiCredentialsScreenState();
}

class _WiFiCredentialsScreenState extends State<WiFiCredentialsScreen> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  Timer? returnTimer;

  void sendCredentials() async {
    String ssid = ssidController.text.trim();
    String password = passwordController.text.trim();
    String dataToSend = '$ssid:$password';

    if (ssid.isNotEmpty && password.isNotEmpty) {
      List<int> bytes = dataToSend.codeUnits;
      await widget.characteristic.write(bytes, withoutResponse: false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wysłano do ESP32!')),
      );

      // Start 30-second timer to go back
      returnTimer?.cancel(); // Cancel any existing timer
      returnTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Oczekuje na połączenie')),
          );
        }
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wprowadź nazwę sieci i hasło')),
      );
    }
  }

  @override
  void dispose() {
    returnTimer?.cancel();
    ssidController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ustawienia sieci')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(labelText: 'nazwa'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'hasło'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendCredentials,
              child: const Text('Prześlij'),
            ),
          ],
        ),
      ),
    );
  }
}
