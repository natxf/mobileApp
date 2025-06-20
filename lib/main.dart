import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'pages/current_data.dart';
import 'pages/data_control.dart';
import 'pages/statistics.dart';
import 'pages/wifi_credentials.dart';
import 'pages/esp_control.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final channel = WebSocketChannel.connect(Uri.parse('URL'));
    channel.sink.add("APP");
    await Future.delayed(Duration(seconds: 2));
    channel.sink.add("ENVIRONMENT_DATA");

    await for (final data in channel.stream) {
      if (data.contains("ENVIRONMENT_DATA")) {
        if (data.contains("humidity=20")) {
          final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
          const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
          const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
          await flutterLocalNotificationsPlugin.initialize(initSettings);

          const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
            'channelId', 'channelName',
            importance: Importance.max, priority: Priority.high,
          );
          const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

          await flutterLocalNotificationsPlugin.show(
            0,
            'Uwaga!',
            'Wilgotność za niska! Sprawdź roślinę!',
            platformDetails,
          );
        }
        break;
      }
    }
    channel.sink.close();
    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nature Smart ESP32',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const ESP32ControlScreen(),
    );
  }
}

class ESP32ControlScreen extends StatefulWidget {
  const ESP32ControlScreen({super.key});

  @override
  State<ESP32ControlScreen> createState() => _ESP32ControlScreenState();
}

class _ESP32ControlScreenState extends State<ESP32ControlScreen> {
  WebSocketChannel? channel;
  Stream? broadcastStream;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? bleCharacteristic;
  bool isESPConnected = false;
  bool isFullyConnected = false;
  List<ScanResult> scanResults = [];
  bool bleCheckInProgress = false;
  bool bleCheckFailed = false;
  Timer? connectionTimeoutTimer;
  Timer? retryTimeoutTimer;
  bool isLoadingConnection = true;
  String connectionStatus = 'Łączenie...';
  bool isScanningBLE = false;
  bool isConnectingBLE = false;
  BluetoothAdapterState bluetoothState = BluetoothAdapterState.unknown;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
    connectWebSocket();
    connectionTimeoutTimer = Timer(const Duration(seconds: 45), () {
      if (!isESPConnected) {
        setState(() {
          isLoadingConnection = false;
          connectionStatus = 'Błąd połączenia. Spróbuj ponownie.';
        });
      }
    });
  }

  Future<void> _initBluetooth() async {
    FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        bluetoothState = state;
      });
    });

    bluetoothState = await FlutterBluePlus.adapterState.first;
  }

  Future<void> _enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się włączyć Bluetooth: $e')),
      );
    }
  }

  Future<void> scanAndConnectBLE() async {
    PermissionStatus locationStatus = await Permission.locationWhenInUse.status;
    if (!locationStatus.isGranted) {
      locationStatus = await Permission.locationWhenInUse.request();
      if (!locationStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brak pozwolenia na lokalizację.')),
        );
        return;
      }
    }

    if (bluetoothState != BluetoothAdapterState.on) {
      await _enableBluetooth();
      bluetoothState = await FlutterBluePlus.adapterState.first;
      if (bluetoothState != BluetoothAdapterState.on) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bluetooth nadal wyłączone. Włącz je ręcznie.')),
        );
        return;
      }
    }

    setState(() {
      isScanningBLE = true;
      scanResults = [];
      connectionStatus = 'Skanowanie urządzeń...';
    });

    try {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      FlutterBluePlus.scanResults.listen((results) {
        setState(() => scanResults = results);
      });

      await Future.delayed(const Duration(seconds: 4));
      FlutterBluePlus.stopScan();

      setState(() {
        isScanningBLE = false;
      });

      if (scanResults.isNotEmpty) {
        ScanResult? selected = await showDialog<ScanResult>(
          context: context,
          builder: (_) => SimpleDialog(
            title: const Text('Wybierz ESP32 Device'),
            children: scanResults.map((r) => SimpleDialogOption(
              child: Text(r.device.name.isNotEmpty
                  ? r.device.name
                  : r.device.remoteId.toString()),
              onPressed: () => Navigator.pop(context, r),
            )).toList(),
          ),
        );

        if (selected != null) {
          setState(() {
            isConnectingBLE = true;
            connectionStatus = 'Łączenie z ${selected.device.name}...';
          });

          try {
            await selected.device.connect(autoConnect: false);
            List<BluetoothService> services = await selected.device.discoverServices();

            for (var service in services) {
              for (var char in service.characteristics) {
                if (char.uuid.toString() == 'beb5483e-36e1-4688-b7f5-ea07361b26a8') {
                  setState(() {
                    connectedDevice = selected.device;
                    bleCharacteristic = char;
                    isConnectingBLE = false;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WiFiCredentialsScreen(characteristic: char),
                    ),
                  );
                  return;
                }
              }
            }

            setState(() {
              isConnectingBLE = false;
              connectionStatus = 'Nie znaleziono odpowiedniej usługi w urządzeniu.';
            });
          } catch (e) {
            setState(() {
              isConnectingBLE = false;
              connectionStatus = 'Błąd połączenia: $e';
            });
          }
        }
      } else {
        setState(() {
          connectionStatus = 'Nie znaleziono urządzeń.';
        });
      }
    } catch (e) {
      setState(() {
        connectionStatus = 'Błąd skanowania: $e';
        isScanningBLE = false;
      });
    }
  }


  void connectWebSocket() {
    retryTimeoutTimer?.cancel();

    channel = WebSocketChannel.connect(Uri.parse('wss://esp32-websocket-server-495y.onrender.com'));
    broadcastStream = channel!.stream.asBroadcastStream();
    channel!.sink.add("APP");
    channel!.sink.add("PING");

    retryTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (!isESPConnected) {
        setState(() {
          isLoadingConnection = false;
          connectionStatus = 'Nie udało się ponownie połączyć.';
        });
      }
    });

    broadcastStream!.listen((data) {
      print("WebSocket Data: $data");
      if (data == "PING" || data == "CONNECTED") {
        connectionTimeoutTimer?.cancel();
        retryTimeoutTimer?.cancel();
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            isESPConnected = true;
            isFullyConnected = true;
            isLoadingConnection = false;
          });
        });
      }
    }, onError: (error) {
      print("WebSocket Error: $error");
      retryTimeoutTimer?.cancel();
      setState(() {
        isLoadingConnection = false;
        connectionStatus = 'Błąd połączenia: $error';
      });
    });
  }
  Future<void> disconnectAndClearESP32() async {
    try {
      await connectedDevice?.disconnect();
    } catch (e) {
      print("Błąd w rozłączaniu: $e");
    }
    setState(() {
      channel = null;
      connectedDevice = null;
      bleCharacteristic = null;
      isESPConnected = false;
      isFullyConnected = false;
    });
  }
  Widget buildDisconnectButton() {
    return ElevatedButton(
      onPressed: disconnectAndClearESP32WithForget,
      child: const Text("Rozłącz i zamopnij urządzenie"),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    );
  }

  Future<void> disconnectAndClearESP32WithForget() async {
    try {
      channel!.sink.add("FORGET");
      await channel?.sink.close();
      await connectedDevice?.disconnect();
    } catch (e) {
      print("Błąd: $e");
    }
    setState(() {
      channel = null;
      connectedDevice = null;
      bleCharacteristic = null;
      isESPConnected = false;
      isFullyConnected = false;
      isLoadingConnection = false;
      connectionStatus = 'Pomyślnie rozłączono urządzenie';
    });
  }

  Widget buildControlButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.lightGreen,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.green),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget buildMainScreen() {
    if (isLoadingConnection || isScanningBLE || isConnectingBLE) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(connectionStatus, style: const TextStyle(fontSize: 16)),
          ],
        ),
      );
    }
    if (!isFullyConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Wyszukaj urządzenie"),
              onPressed: scanAndConnectBLE,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text("Ponowne łączenie"),
              onPressed: () {
                setState(() {
                  isLoadingConnection = true;
                  connectionStatus = 'Ponowne łączenie...';
                });
                connectWebSocket();
              },
            ),
            const SizedBox(height: 16),
            Text(connectionStatus),
          ],
        ),
      );
    }    else {
      return Column(
        children: [
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                buildControlButton(
                  icon: Icons.lightbulb_outline,
                  label: "Sterowanie",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ESPControlPage(channel: channel!,  stream: broadcastStream!),
                      ),
                    );
                  },
                ),
                buildControlButton(
                  icon: Icons.data_usage,
                  label: "Aktualne Dane",
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CurrentDataScreen(channel: channel!, stream: broadcastStream!),
                  )),
                ),
                buildControlButton(
                  icon: Icons.settings,
                  label: "Ustawienia",
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => DataControlScreen(channel: channel!, stream: broadcastStream!),
                  )),
                ),
                buildControlButton(
                  icon: Icons.show_chart,
                  label: "Statystyki",
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const StatisticsScreen(),
                  )),
                ),
              ],
            ),
          ),
          buildDisconnectButton(), 
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nature Smart ESP32"),
        backgroundColor: Colors.lightGreen,
      ),
      body: buildMainScreen(),
    );
  }

  @override
  void dispose() {
    connectionTimeoutTimer?.cancel();
    channel?.sink.close();
    connectedDevice?.disconnect();
    super.dispose();
  }
}
