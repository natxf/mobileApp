import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/sensors_data.dart';
import '../../utils/supabase.dart';
import '../utils/sensors_utils.dart';

class TempHumChart extends StatefulWidget {
  const TempHumChart({super.key});

  @override
  State<TempHumChart> createState() => _TempHumChartState();
}

class _TempHumChartState extends State<TempHumChart> {
  List<SensorsData> _sensorData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    supaInit();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final averagedData = await fetchAndAverageSensorData(
          fields: ['temperature', 'humidity'],
      );

      if (mounted){
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
          'Warunki zewnętrzne',
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
          title: ChartTitle(text: 'Średnia dzienna temperatura i wilgotność'),
          legend: Legend(isVisible: true),
          tooltipBehavior: TooltipBehavior(enable: true),
          primaryXAxis: CategoryAxis(
            labelRotation: 45,
            majorGridLines: const MajorGridLines(width: 0),
          ),
          axes: <ChartAxis>[
            NumericAxis(
              name: 'humidityAxis',
              opposedPosition: true,
              minimum: 0,
              maximum: 100,
              interval: 10,
              title: AxisTitle(text: 'Wilgotność (%)'),
            ),
          ],
          series: <CartesianSeries>[
            // Bar chart for humidity
            ColumnSeries<SensorsData, String>(
              name: 'Wilgotność',
              yAxisName: 'humidityAxis',
              dataSource: _sensorData,
              xValueMapper: (SensorsData data, _) =>
                  DateFormat('dd.MM').format(data.createdAt),
              yValueMapper: (SensorsData data, _) => data.humidity,
              color: Colors.blue.withOpacity(0.5),
              width: 0.6,
            ),
            // Line chart for temperature
            LineSeries<SensorsData, String>(
              name: 'Temperatura',
              dataSource: _sensorData,
              xValueMapper: (SensorsData data, _) =>
                  DateFormat('dd.MM').format(data.createdAt),
              yValueMapper: (SensorsData data, _) => data.temperature,
              markerSettings: const MarkerSettings(isVisible: true),
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
