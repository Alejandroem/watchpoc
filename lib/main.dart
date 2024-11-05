import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'WhistleBox HR Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _heartRate = 0;
  final MethodChannel channel = const MethodChannel('com.example.watchApp');

  Future<void> sendDataToNative() async {
    try {
      // Send data to Native
      await channel.invokeMethod(
        "flutterToWatch",
        {"method": "sendHRToNative", "data": _heartRate},
      );
    } on PlatformException catch (e) {
      // Handle errors in communication with native code
      debugPrint("Failed to send data to native: ${e.message}");
    } catch (e) {
      // Handle any other errors
      debugPrint("Unexpected error: $e");
    }
  }

  Future<void> _initFlutterChannel() async {
    channel.setMethodCallHandler((call) async {
      try {
        // Receive data from Native
        switch (call.method) {
          case "sendHRToFlutter":
            // Safely extract data and handle missing or unexpected fields
            final data = call.arguments["data"];
            if (data is Map && data.containsKey("counter")) {
              setState(() {
                _heartRate = data["counter"] ?? 0;
              });
              sendDataToNative();
            } else {
              debugPrint("Data format is invalid or missing 'counter' field.");
            }
            break;
          default:
            debugPrint("Unknown method called from native: ${call.method}");
            break;
        }
      } on PlatformException catch (e) {
        debugPrint("Error handling native call: ${e.message}");
      } catch (e) {
        debugPrint("Unexpected error: $e");
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initFlutterChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              '$_heartRate BPM',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold
              ),
            ),
            SizedBox(height: 50,),            
          ],
        ),
      ),
    );
  }
}
