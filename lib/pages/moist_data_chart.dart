import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:test_websocket/utils/sensors_utils.dart';
import '../../models/sensors_data.dart';
import '../../utils/supabase.dart';

class MoistChart extends StatefulWidget{
  const MoistChart({super.key});

  @override
  State<MoistChart> createState() => _MoistChartState();
}

class _MoistChartState extends State<MoistChart> {
  List<SensorsData> _sensorData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try{
      final averagedData = await fetchAndAverageSensorData(
          fields: ['moisture']
      );

      if(mounted){
        setState(() {
          _sensorData = averagedData;
          isLoading = false;
        });
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd bazy danych: $e'))
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
          'Wilgotność gleby',
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
          title: ChartTitle(text: 'Wilgotność gleby'),
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
            title: AxisTitle(text: 'Wilgotność gleby (%)'),
          ),
          series: <CartesianSeries>[
            ColumnSeries<SensorsData, String>(
                name: 'Wilgotność gleby',
                dataSource: _sensorData,
              xValueMapper: (SensorsData data, _) =>
                  DateFormat('dd.MM').format(data.createdAt),
              yValueMapper: (SensorsData data, _) => data.moisture,
              color: Colors.blue.withOpacity(0.5),
              width: 0.6,
            )
          ],
        ),
      )
    );
  }
}