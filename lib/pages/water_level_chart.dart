import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/sensors_data.dart';
import '../../utils/supabase.dart';
import '../utils/sensors_utils.dart';

class WaterLevelChart extends StatefulWidget {
  const WaterLevelChart({super.key});

  @override
  State<WaterLevelChart> createState() => _WaterLevelChartState();
}

class _WaterLevelChartState extends State<WaterLevelChart> {
  List<SensorsData> _sensorData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final averagedData = await fetchAndAverageSensorData(
        fields: ['water_level'],
      );
      if (mounted) {
        setState(() {
          _sensorData = averagedData;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd bazy danych: $e')),
        );
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Poziom wody',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'Roboto',
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightGreen,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SfCartesianChart(
          title: ChartTitle(text: 'Poziom wody'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          primaryXAxis: CategoryAxis(
            labelRotation: 45,
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 20,
            interval: 1,
            title: AxisTitle(text: "Poziom wody (cm)"),
          ),
          series: <CartesianSeries>[
            AreaSeries<SensorsData, String>(
              name: 'Poziom wody',
              dataSource: _sensorData,
              xValueMapper: (SensorsData data, _) =>
                  DateFormat('dd.MM').format(data.createdAt),
              yValueMapper: (SensorsData data, _) => data.waterLevel,
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.blue,
            )
          ],
        ),
      ),
    );
  }
}
