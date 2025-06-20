import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../models/sensors_data.dart';
import '../../utils/supabase.dart';
import '../utils/sensors_utils.dart';

class BrighnessChart extends StatefulWidget {
  const BrighnessChart({super.key});

  @override
  State<BrighnessChart> createState() => _BrighnessChartState();
}

class _BrighnessChartState extends State<BrighnessChart> {
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
        fields: ['brightness'],
      );
      if (mounted) {
        setState(() {
          _sensorData = averagedData;
          isLoading = false;
        });
        print(averagedData);
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
          'Naświetlenie',
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
          title: ChartTitle(text: 'Naświetlenie'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          primaryXAxis: CategoryAxis(
            labelRotation: 45,
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            minimum: 0,
            maximum: 100,
            interval: 10,
            title: AxisTitle(text: "Naświetlenie %"),
          ),
          series: <CartesianSeries>[
            AreaSeries<SensorsData, String>(
              name: 'Naświetlenie',
              dataSource: _sensorData,
              xValueMapper: (SensorsData data, _) =>
                  DateFormat('dd.MM').format(data.createdAt),
              yValueMapper: (SensorsData data, _) => data.brightness,
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.yellow,
            )
          ],
        ),
      ),
    );
  }
}
