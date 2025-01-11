import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../common_widgets/chart_widget.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, List<double>> data = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await fetchDataAndUploadToFirestore(); // First, fetch and upload data to Firestore
    data = await getDataFromFirestore();   // Then, retrieve data from Firestore
    setState(() {});                       // Refresh UI with the new data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
          title: const Text("XAU/USD Prediction Charts")
      ),
      body: data.isNotEmpty
          ? SingleChildScrollView(
            child: Column(
                    children: [
                      const Text(
                        'Predicted XAU/USD for Upcoming 30 Days',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10,),
            PredictionChart(
              data: data['predicted_next_30_days'] ?? [],
              startDate: DateTime.now(),
            ),

                      const SizedBox(height: 20),
                      const Text(
                        'Past 30 Days XAU/USD - Actual (Green) vs Predicted (Red)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10,),

            PastComparisonChart(
              actualData: data['actual_last_30_days'] ?? [],
              predictedData: data['predicted_past_30_days'] ?? [],
              startDate: DateTime.now().subtract(const Duration(days: 30)),
            ),
                    ],
                  ),
          )
          : const Center(child: CircularProgressIndicator()),
    );
  }


  Future<void> fetchDataAndUploadToFirestore() async {
    try {
      // Fetch data from the server
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/predict-xau'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<double> actualLast30Days = List<double>.from(data['actual_last_30_days']);
        List<double> predictedNext30Days = List<double>.from(data['predicted_next_30_days']);
        List<double> predictedPast30Days = List<double>.from(data['predicted_past_30_days']);

        // Upload data to Firestore
        await FirebaseFirestore.instance.collection('gold_predictions').doc('xau_predictions').set({
          'actual_last_30_days': actualLast30Days,
          'predicted_next_30_days': predictedNext30Days,
          'predicted_past_30_days': predictedPast30Days,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print("Data uploaded successfully!");
      } else {
        print("Failed to fetch data from the server.");
      }
    } catch (e) {
      print("Error uploading data: $e");
    }
  }

  Future<Map<String, List<double>>> getDataFromFirestore() async {
    try {
      final DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('gold_predictions')
          .doc('xau_predictions')
          .get();

      if (snapshot.exists) {
        List<double> actualLast30Days = List<double>.from(snapshot['actual_last_30_days']);
        List<double> predictedNext30Days = List<double>.from(snapshot['predicted_next_30_days']);
        List<double> predictedPast30Days = List<double>.from(snapshot['predicted_past_30_days']);

        return {
          'actual_last_30_days': actualLast30Days,
          'predicted_next_30_days': predictedNext30Days,
          'predicted_past_30_days': predictedPast30Days,
        };
      } else {
        throw Exception("Document does not exist.");
      }
    } catch (e) {
      print("Failed to get data: $e");
      return {};
    }
  }



}
