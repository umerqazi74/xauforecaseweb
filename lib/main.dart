import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const XAUPredictionApp());
}

class XAUPredictionApp extends StatelessWidget {
  const XAUPredictionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PredictionHome(),
    );
  }
}

class PredictionHome extends StatefulWidget {
  const PredictionHome({super.key});

  @override
  _PredictionHomeState createState() => _PredictionHomeState();
}

class _PredictionHomeState extends State<PredictionHome> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    uploadDataToFirestore();
  }

  Future<void> uploadDataToFirestore() async {
    try {
      // Fetch data from APIs
      final hourlyResponse = await http.get(Uri.parse('http://127.0.0.1:5000/predict-xau/hourly'));
      final dailyResponse = await http.get(Uri.parse('http://127.0.0.1:5000/predict-xau/daily'));

      if (hourlyResponse.statusCode == 200 && dailyResponse.statusCode == 200) {
        final hourlyData = json.decode(hourlyResponse.body)['predicted'];
        final dailyData = json.decode(dailyResponse.body)['predicted'];

        final now = DateTime.now();

        // Format timestamps
        final hourlyTimestamps = List.generate(24, (index) => DateFormat('HH:00').format(now.add(Duration(hours: index))));
        final dailyTimestamps = List.generate(dailyData.length, (index) => DateFormat('dd').format(now.add(Duration(days: index))));

        // Upload hourly predictions
        await firestore.collection("hourly_predictions").doc("latest").set({
          "last_updated": now.toIso8601String(),
          "timestamps": hourlyTimestamps,
          "predictions": hourlyData,
        });

        // Upload daily predictions
        await firestore.collection("daily_predictions").doc("latest").set({
          "last_updated": now.toIso8601String(),
          "timestamps": dailyTimestamps,
          "predictions": dailyData,
        });

        print("Data uploaded to Firestore successfully!");
      } else {
        print("Error fetching data.");
      }
    } catch (e) {
      print("Error uploading to Firestore: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("XAU Predictions"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Next 24 Hours"),
              Tab(text: "Daily"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            PredictionTab(collection: "hourly_predictions", title: "Next 24 Hours"),
            PredictionTab(collection: "daily_predictions", title: "Daily Prediction"),
          ],
        ),
      ),
    );
  }
}

class PredictionTab extends StatelessWidget {
  final String collection;
  final String title;

  const PredictionTab({super.key, required this.collection, required this.title});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return FutureBuilder<DocumentSnapshot>(
      future: firestore.collection(collection).doc("latest").get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final lastUpdated = data['last_updated'];
          final timestamps = List<String>.from(data['timestamps']);
          final predictions = List<double>.from(data['predictions']);

          // Prepare spots for FlChart
          final spots = List.generate(predictions.length, (index) {
            return FlSpot(index.toDouble(), predictions[index]);
          });

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                Text("Last updated: ${DateFormat.yMMMEd().add_Hms().format(DateTime.parse(lastUpdated))}"),
                Container(
                  height: 300,
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50, // Adjust to fit larger numbers
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  value.toStringAsFixed(2), // Format with 2 decimal places
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50, // Adjust to fit larger numbers
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  value.toStringAsFixed(2), // Format with 2 decimal places
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              // Convert `value` to integer index
                              final index = value.toInt();
                              if (index < 0 || index >= timestamps.length) return Container();

                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(timestamps[index], style: const TextStyle(fontSize: 10)),
                              );
                            },
                            reservedSize: 30,
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 2,
                          color: Colors.blue,
                        ),
                      ],
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return const Center(child: Text("Error fetching data."));
        }
      },
    );
  }
}












































// import 'dart:convert';
//
// import 'package:firebase_core/firebase_core.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:xau_forecaste/screens/charts_screen.dart';
//
// import 'firebase_options.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// Future<void> uploadDataToFirestore(
//     List<double> actualLast30Days,
//     List<double> predictedLast30Days,
//     List<double> predictedNext30Days
//     ) async {
//   try {
//     // Reference to your Firestore collection (e.g., "gold_predictions")
//     final CollectionReference collection = FirebaseFirestore.instance.collection('gold_predictions');
//
//     // Upload data as a document with two fields
//     await collection.doc('xau_predictions').set({
//       'actual_last_30_days': actualLast30Days,
//       'predicted_last_30_days': predictedLast30Days,
//       'predicted_next_30_days': predictedNext30Days,
//       'timestamp': FieldValue.serverTimestamp(),  // Optional: to add a timestamp for reference
//     });
//
//     print("Data uploaded successfully!");
//   } catch (e) {
//     print("Failed to upload data: $e");
//   }
// }


//
// Future<void> main() async {
//
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'XAU-FORECAST',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home:   MyHomePage(),
//     );
//   }
// }




// class PredictionGraphsScreen extends StatefulWidget {
//   const PredictionGraphsScreen({super.key});
//
//   @override
//   _PredictionGraphsScreenState createState() => _PredictionGraphsScreenState();
// }
//
// class _PredictionGraphsScreenState extends State<PredictionGraphsScreen> {
//   PredictionData? predictionData;
//
//   @override
//   void initState() {
//     super.initState();
//     fetchPredictionData().then((data) async {
//       setState(() {
//         predictionData = data;
//       });
//
//      await uploadDataToFirestore(
//           predictionData!.actualLast30Days,
//           predictionData!.predictedPast30Days,
//           predictionData!.predictedNext30Days
//       );
//
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('XAU/USD Prediction Graphs'),
//       ),
//       body: predictionData == null
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             children: [
//               const Text(
//                 'Predicted XAU/USD for Upcoming 30 Days',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10,),
//               SizedBox(
//                 height: 300,
//                 child: PredictionChart(
//                   data: predictionData!.predictedNext30Days,
//                   startDate: DateTime.now(),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Past 30 Days XAU/USD - Actual (Green) vs Predicted (Red)',
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 10,),
//               SizedBox(
//                 height: 300,
//                 child: PastComparisonChart(
//                   actualData: predictionData!.actualLast30Days,
//                   predictedData: predictionData!.predictedPast30Days,
//                   startDate: DateTime.now().subtract(const Duration(days: 30)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
// class PredictionData {
//   List<double> actualLast30Days;
//   List<double> predictedNext30Days;
//   List<double> predictedPast30Days;
//
//   PredictionData({
//     required this.actualLast30Days,
//     required this.predictedNext30Days,
//     required this.predictedPast30Days,
//   });
//
//   factory PredictionData.fromJson(Map<String, dynamic> json) {
//     return PredictionData(
//       actualLast30Days: List<double>.from(json['actual_last_30_days']),
//       predictedNext30Days: List<double>.from(json['predicted_next_30_days']),
//       predictedPast30Days: List<double>.from(json['predicted_past_30_days']),
//     );
//   }
// }
//
// Future<PredictionData?> fetchPredictionData() async {
//   final url = Uri.parse('http://127.0.0.1:5000/predict-xau');
//   try {
//     final response = await http.get(url);
//
//     if (response.statusCode == 200) {
//       return PredictionData.fromJson(jsonDecode(response.body));
//     } else {
//       throw Exception('Failed to load data');
//     }
//   } catch (e) {
//     print('Error: $e');
//     return null;
//   }
// }
//
//
//
//
//
// class PredictionChart extends StatelessWidget {
//   final List<double> data;
//   final DateTime startDate;
//
//   PredictionChart({super.key, required this.data, required this.startDate});
//
//   // Generate x-axis labels with formatted dates at 5-day intervals
//   String getFormattedDate(int index) {
//     DateTime date = startDate.add(Duration(days: index));
//     return DateFormat('MMM dd').format(date);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return LineChart(
//       LineChartData(
//         lineBarsData: [
//           LineChartBarData(
//             spots: data
//                 .asMap()
//                 .entries
//                 .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
//                 .toList(),
//             isCurved: true,
//             color: Colors.blueAccent,
//             belowBarData: BarAreaData(show: true, color: Colors.blueAccent.withOpacity(0.2)),
//             dotData: const FlDotData(show: false),
//           ),
//         ],
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 32,  // Reserve more space for date labels
//               interval: 6,
//               getTitlesWidget: (value, meta) {
//                 int index = value.toInt();
//                 if (index >= 0 && index < data.length) {
//                   return Text(getFormattedDate(index), style: const TextStyle(fontSize: 10));
//                 }
//                 return const Text('');
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 33,  // Reserve extra space for y-axis values
//               interval: 8,
//               getTitlesWidget: (value, meta) => Text('${value.toInt()}',style: TextStyle(fontSize: 10),),
//             ),
//           ),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border.all(color: Colors.grey, width: 1),
//         ),
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: true,
//           horizontalInterval: 20,
//           verticalInterval: 5,
//           getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
//           getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
//         ),
//       ),
//     );
//   }
// }
//
// class PastComparisonChart extends StatelessWidget {
//   final List<double> actualData;
//   final List<double> predictedData;
//   final DateTime startDate;
//
//   PastComparisonChart({super.key,
//     required this.actualData,
//     required this.predictedData,
//     required this.startDate,
//   });
//
//   String getFormattedDate(int index) {
//     DateTime date = startDate.add(Duration(days: index));
//     return DateFormat('MMM dd').format(date);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return LineChart(
//       LineChartData(
//         lineBarsData: [
//           LineChartBarData(
//             spots: actualData
//                 .asMap()
//                 .entries
//                 .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
//                 .toList(),
//             isCurved: true,
//             color: Colors.green,
//             dotData: const FlDotData(show: false),
//             barWidth: 3,
//           ),
//           LineChartBarData(
//             spots: predictedData
//                 .asMap()
//                 .entries
//                 .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
//                 .toList(),
//             isCurved: true,
//             color: Colors.redAccent,
//             dotData: const FlDotData(show: false),
//             barWidth: 3,
//           ),
//         ],
//         titlesData: FlTitlesData(
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 32,
//               interval: 5,
//               getTitlesWidget: (value, meta) {
//                 int index = value.toInt();
//                 if (index >= 0 && index < actualData.length + predictedData.length) {
//                   return Text(getFormattedDate(index), style: const TextStyle(fontSize: 10));
//                 }
//                 return const Text('');
//               },
//             ),
//           ),
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               reservedSize: 33,
//               interval: 20,
//               getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
//             ),
//           ),
//           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//         ),
//         borderData: FlBorderData(
//           show: true,
//           border: Border.all(color: Colors.grey, width: 1),
//         ),
//         gridData: FlGridData(
//           show: true,
//           drawVerticalLine: true,
//           horizontalInterval: 20,
//           verticalInterval: 5,
//           getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
//           getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
//         ),
//       ),
//     );
//   }
// }