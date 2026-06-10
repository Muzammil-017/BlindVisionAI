import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;


List<CameraDescription> cameras = [];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(ObjectDetectionApp());
}

class ObjectDetectionApp extends StatelessWidget {
  const ObjectDetectionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Object Detection',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1C1C1E),
        primaryColor: Colors.blueAccent,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'Roboto',
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = <Widget>[
    DashboardScreen(),
    DetectionScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF2C2C2E),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Detect'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  List<dynamic> detections = [];
  final FlutterTts flutterTts = FlutterTts();
  Timer? autoDetectTimer;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    var statuses = await [Permission.camera, Permission.microphone].request();
    if (statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted) {
      _controller = CameraController(cameras[0], ResolutionPreset.low, enableAudio: false);
      await _controller!.initialize();
      setState(() => _isCameraInitialized = true);
      autoDetectTimer = Timer.periodic(
        Duration(seconds: 6),
        (timer) => _detectObjects(),
      );
    }
  }

  Future<void> _detectObjects() async {
  if (_isDetecting) return;
  if (_controller == null || !_controller!.value.isInitialized) return;

  _isDetecting = true;

  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/object.jpg');

    XFile picture = await _controller!.takePicture();
    await picture.saveTo(file.path);

    var uri = Uri.parse("http://10.125.118.142:8000/detect");

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final List data = jsonDecode(responseBody);

      setState(() {
        detections = data;
      });

      if (detections.isNotEmpty) {
        final names = detections
            .map<String>((det) => det['name'].toString())
            .toSet()
            .toList();

        await flutterTts.speak("Detected ${names.join(', ')}");
      }
    } else {
      print("Backend error: ${response.statusCode}");
    }
  } catch (e) {
    print("Detection error: $e");
  } finally {
    _isDetecting = false;
  }
}


  @override
  void dispose() {
    _controller?.dispose();
    autoDetectTimer?.cancel();
    super.dispose();
  }

Widget buildCameraPreview() {
  if (_controller == null || !_controller!.value.isInitialized) {
    return const SizedBox();
  }

  return Center(
    child: AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: CameraPreview(_controller!),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: _isCameraInitialized && _controller != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    buildCameraPreview(),
                    CustomPaint(
                      painter: BoundingBoxPainter(
                        detections: detections,
                        imageSize: Size(
                          _controller!.value.previewSize!.height,
                          _controller!.value.previewSize!.width,
                        ),
                        screenSize: MediaQuery.of(context).size,
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recent Detections', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: detections
                        .map((det) =>
                            detectionTile("${det['name']} detected", Colors.green))
                        .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget detectionTile(String title, Color dotColor) {
    return Card(
      color: Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        leading: Icon(Icons.circle, color: dotColor, size: 12),
        title: Text(title, style: TextStyle(fontSize: 16)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      ),
    );
  }
}

class DetectionScreen extends StatelessWidget {
  const DetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Detection Screen')); // Placeholder
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Profile Screen')); // Placeholder
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<dynamic> detections;
  final Size imageSize;
  final Size screenSize;

  BoundingBoxPainter({
    required this.detections,
    required this.imageSize,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    for (var det in detections) {
      double xScale = screenSize.width / imageSize.width;
      double yScale = screenSize.height / imageSize.height;

      double left = det['xmin'] * xScale;
      double top = det['ymin'] * yScale;
      double right = det['xmax'] * xScale;
      double bottom = det['ymax'] * yScale;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);

      final label =
          "${det['name']} ${(det['confidence'] * 100).toStringAsFixed(1)}%";

      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          backgroundColor: Colors.black54,
        ),
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(left, top - 20));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
