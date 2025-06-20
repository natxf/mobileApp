import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class DataControlScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final Stream stream;

  const DataControlScreen({
    super.key,
    required this.channel,
    required this.stream,
  });

  @override
  _DataControlScreenState createState() => _DataControlScreenState();
}

class _DataControlScreenState extends State<DataControlScreen> {
  String dTemp = "";
  String dHum = "";
  String dMoist = "";
  String minWater = "";
  String dBright = "";
  bool isLoading = true;

  final TextEditingController tempController = TextEditingController();
  final TextEditingController humController = TextEditingController();
  final TextEditingController moistController = TextEditingController();
  final TextEditingController waterController = TextEditingController();
  final TextEditingController brightController = TextEditingController();

  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    widget.channel.sink.add("DESIRED_ENVIRONMENT");

    _subscription = widget.stream.listen((data) {
      try {
        var jsonData = jsonDecode(data);
        if (jsonData.containsKey("dTemp") &&
            jsonData.containsKey("dHum") &&
            jsonData.containsKey('dMoist') &&
            jsonData.containsKey('minWater') &&
            jsonData.containsKey('dBright')) {
          if(mounted){
            setState(() {
              dTemp = jsonData['dTemp'].toString();
              dHum = jsonData['dHum'].toString();
              dMoist = jsonData['dMoist'].toString();
              minWater = jsonData['minWater'].toString();
              dBright = jsonData['dBright'].toString();
            });
          }
        }
        isLoading = false;
      } catch (e) {
        print("Error parsing JSON: $e");
      }
    });
  }

  @override
  void dispose(){
    _subscription.cancel();
    super.dispose();
  }

  void sendData() {
    int? newTemp = int.tryParse(tempController.text);
    int? newHum = int.tryParse(humController.text);
    int? newMoist = int.tryParse(moistController.text);
    int? newBright = int.tryParse(brightController.text);
    int? newWater = int.tryParse(waterController.text);

    final Map<String, dynamic> override = {};

    if (newTemp != null && newTemp >= 0 && newTemp <= 40)
      override["setTemp"] = newTemp;
    if (newHum != null && newHum >= 0 && newHum <= 100)
      override["setHum"] = newHum;
    if (newMoist != null && newMoist >= 0 && newMoist <= 100)
      override["setMoist"] = newMoist;
    if (newBright != null && newBright >= 0 && newBright <= 100)
      override["setBright"] = newBright;
    if (newWater != null && newWater >= 0 && newWater <= 12)
      override["setWater"] = newWater;

    if (override.isNotEmpty) {
      widget.channel.sink.add(jsonEncode(override));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Zapisuję zmiany.", textAlign: TextAlign.center),
          duration: Duration(seconds: 2),
        ),
      ).closed.then((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błędne dane wejściowe!", textAlign: TextAlign.center,)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            "Ustawienia",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto',
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.lightGreen,
          centerTitle: true),
      body: isLoading
        ? const Center(child: CircularProgressIndicator())
        :
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            buildSettingTile("Temperatura", dTemp, tempController),
            buildSettingTile("Wilgotność otoczenia", dHum, humController),
            buildSettingTile("Wilgotność gleby", dMoist, moistController),
            buildSettingTile("Jasność", dBright, brightController),
            buildSettingTile("Minimalna ilość wody", minWater, waterController),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: sendData,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.lightGreen,
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSettingTile(String label, String currentValue, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label (aktualna: ${currentValue})", style: TextStyle(fontSize: 18)),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: "Nowa $label",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}
