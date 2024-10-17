import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HeartRateScreen(),
    );
  }
}

class HeartRateScreen extends StatefulWidget {
  @override
  _HeartRateScreenState createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  static const platform = MethodChannel('com.example.yourapp/healthkit');

  String _heartRate = "Unknown";

  Future<void> _getHeartRate() async {
    try {
      final double result = await platform.invokeMethod('getHeartRate');
      setState(() {
        _heartRate = result.toString();
      });
    } on PlatformException catch (e) {
      setState(() {
        _heartRate = "Failed to get heart rate: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Heart Rate")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Heart Rate: $_heartRate bpm'),
            ElevatedButton(
              onPressed: _getHeartRate,
              child: Text("Fetch Heart Rate"),
            ),
          ],
        ),
      ),
    );
  }
}
