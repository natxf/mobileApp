import 'package:flutter/material.dart';
import '../utils/supabase.dart';
import 'temp_hum_chart.dart';
import 'moist_data_chart.dart';
import 'water_level_chart.dart';
import 'brightness_chart.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    supaInit();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
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
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statystyki',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'Roboto',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightGreen,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            buildControlButton(
              icon: Icons.thermostat,
              label: 'Warunki zewnętrzne',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TempHumChart()),
                );
              },
            ),
            buildControlButton(
              icon: Icons.water_drop,
              label: 'Wilgotność gleby',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MoistChart()),
                );
              },
            ),
            buildControlButton(
              icon: Icons.wb_sunny,
              label: 'Naświetlenie',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BrighnessChart()),
                );
              },
            ),
            buildControlButton(
              icon: Icons.opacity,
              label: 'Poziom wody',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WaterLevelChart()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
