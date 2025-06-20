import '../models/sensors_data.dart';
import 'supabase.dart';

Map<String, List<SensorsData>> groupByDay(List<SensorsData> data) {
  final Map<String, List<SensorsData>> grouped = {};
  for (var item in data) {
    final key = "${item.createdAt.year}-${item.createdAt.month}-${item.createdAt.day}";
    grouped.putIfAbsent(key, () => []).add(item);
  }
  return grouped;
}

List<SensorsData> computeDailyAverages(List<SensorsData> data) {
  final grouped = groupByDay(data);
  final List<SensorsData> averaged = [];

  grouped.forEach((key, list) {
    final dateParts = key.split("-");
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    double average(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a+b)/list.length;

    averaged.add(SensorsData(
      createdAt: date,
      temperature: average(list.map((e) => e.temperature).toList()),
      humidity: average(list.map((e) => e.humidity).toList()),
      brightness: average(list.map((e) => e.brightness.toDouble()).toList()),
      moisture: average(list.map((e) => e.moisture.toDouble()).toList()),
      waterLevel: average(list.map((e) => e.waterLevel).toList()),
    ));
  });

  averaged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return averaged;
}

Future<List<SensorsData>> fetchAndAverageSensorData({
  required List<String> fields,
  int daysBack = 30,
}) async {
  final fromDate = DateTime.now().subtract(Duration(days: daysBack));

  final response = await supabase
      .from('esp_data')
      .select(['created_at', ...fields].join(', '))
      .gte('created_at', fromDate.toIso8601String())
      .order('created_at', ascending: true);

  final rawData = (response as List)
      .map((e) => SensorsData.fromJson(e))
      .toList();

  return computeDailyAverages(rawData);
}
