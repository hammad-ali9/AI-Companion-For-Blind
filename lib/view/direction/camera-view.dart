import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ultralytics_yolo/ultralytics_yolo.dart';
import 'package:ultralytics_yolo/yolo_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo_example/view/home/floating-map.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ultralytics_yolo_example/utils/constants/colors.dart';
import 'package:vibration/vibration.dart';

// void main() {
//   runApp(const MyApp());
// }

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _MyAppState();
}

// // In your _MyAppState class, add this in initState:
// @override
// void initState() {
//   super.initState();
//   _startHapticFeedback();
// }

// // To stop haptic feedback when the StreamBuilder is no longer needed (e.g., in dispose):
// @override
// void dispose() {
//   Vibration.cancel(); // Stop vibration when the widget is disposed
//   super.dispose();
// }

class _MyAppState extends State<CameraView> {
  final controller = UltralyticsYoloCameraController();
  String? _turnInstruction;

  FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(0.7);
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
  }


  @override
  Widget build(BuildContext context) {
    final List list =
        ModalRoute.of(context)?.settings.arguments as List<dynamic>;
    final address = list[0];
    final LatLng destination = list[2];
    final LatLng currentLocation = list[1];

    return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
          centerTitle: true,
          title: Text(
            address,
            style: const TextStyle(color: Colors.white),
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.black,
        ),
        body: FutureBuilder<bool>(
          future: _checkPermissions(),
          builder: (context, snapshot) {
            final allPermissionsGranted = snapshot.data ?? false;

            return !allPermissionsGranted
                ? const Center(
              child: Text("Error requesting permissions"),
            )
                : FutureBuilder<ObjectDetector>(
              future: _initObjectDetectorWithLocalModel(),
              builder: (context, snapshot) {
                final predictor = snapshot.data;

                return predictor == null
                    ? Container()
                    : Stack(
                  children: [
                    UltralyticsYoloCameraPreview(
                      controller: controller,
                      predictor: predictor,
                      onCameraCreated: () {
                        predictor.loadModel(useGpu: true);
                      },
                    ),
                    Positioned(
                      top: 50,
                      right: 20,
                      child: FloatingMap(
                        currentLocation: currentLocation,
                        destination: destination,
                        onTurnCallback: (instruction) {
                          if (mounted) {
                            setState(() {
                              _turnInstruction = instruction;
                            });
                            if (_turnInstruction != null &&
                                _turnInstruction != '') {
                              speak(_turnInstruction!);
                            }
                          }
                        },
                      ),
                    ),
                    StreamBuilder<double?>(
                      stream: predictor.inferenceTime,
                      builder: (context, snapshot) {
                        final inferenceTime = snapshot.data;
                        if (inferenceTime != null && inferenceTime > 500) {
                          _startHapticFeedback(); // Start haptic feedback when inference begins
                        }

                        return StreamBuilder<double?>(
                          stream: predictor.fpsRate,
                          builder: (context, snapshot) {
                            final fpsRate = snapshot.data;

                            return Times(
                              inferenceTime: inferenceTime,
                              fpsRate: fpsRate,
                            );
                          },
                        );
                      },
                    ),
                    // if (_turnInstruction != null)
                    //   Positioned(
                    //     bottom: 20,
                    //     left: 20,
                    //     right: 20,
                    //     child: Container(
                    //       padding: const EdgeInsets.all(10),
                    //       decoration: BoxDecoration(
                    //         color: Colors.black.withOpacity(0.7),
                    //         borderRadius: BorderRadius.circular(10),
                    //       ),
                    //       child: Text(
                    //         _turnInstruction!,
                    //         style: const TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.bold,
                    //         ),
                    //         textAlign: TextAlign.center,
                    //       ),
                    //     ),
                    //   ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<ObjectDetector> _initObjectDetectorWithLocalModel() async {
    // FOR IOS
    // final modelPath = await _copy('assets/yolov8n.mlmodel');
    // final model = LocalYoloModel(
    //   id: '',
    //   task: Task.detect,
    //   format: Format.coreml,
    //   modelPath: modelPath,
    // );
    // FOR ANDROID
    final modelPath = await _copy('assets/best.tflite');
    final metadataPath = await _copy('assets/metadata.yaml');
    final model = LocalYoloModel(
      id: '',
      task: Task.detect,
      format: Format.tflite,
      modelPath: modelPath,
      metadataPath: metadataPath,
    );

    return ObjectDetector(model: model);
  }

  // Future<ImageClassifier> _initImageClassifierWithLocalModel() async {
  //   final modelPath = await _copy('assets/yolov8n-cls.mlmodel');
  //   final model = LocalYoloModel(
  //     id: '',
  //     task: Task.classify,
  //     format: Format.coreml,
  //     modelPath: modelPath,
  //   );

  //   final modelPath = await _copy('assets/yolov8n-cls.bin');
  //   final paramPath = await _copy('assets/yolov8n-cls.param');
  //   final metadataPath = await _copy('assets/metadata-cls.yaml');
  //   final model = LocalYoloModel(
  //     id: '',
  //     task: Task.classify,
  //     modelPath: modelPath,
  //     paramPath: paramPath,
  //     metadataPath: metadataPath,
  //   );

  //   return ImageClassifier(model: model);
  // }

  Future<String> _copy(String assetPath) async {
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  Future<bool> _checkPermissions() async {
    List<Permission> permissions = [];

    var cameraStatus = await Permission.camera.status;
    if (!cameraStatus.isGranted) permissions.add(Permission.camera);

    var storageStatus = await Permission.photos.status;
    if (!storageStatus.isGranted) permissions.add(Permission.photos);

    if (permissions.isEmpty) {
      return true;
    } else {
      try {
        Map<Permission, PermissionStatus> statuses = await permissions.request();
        return statuses.values.every((status) => status == PermissionStatus.granted);
      } on Exception catch (_) {
        return false;
      }
    }
  }
}

void _startHapticFeedback() {
  // Trigger haptic feedback after 1-second delay
  Future.delayed(const Duration(seconds: 2), () {
    Vibration.vibrate(pattern: [500, 500], repeat: -1); // Continuous vibration (500ms on, 500ms off, loops until canceled)
  });
}
class Times extends StatelessWidget {
  const Times({
    super.key,
    required this.inferenceTime,
    required this.fpsRate,
  });

  final double? inferenceTime;
  final double? fpsRate;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
              color: Colors.black54,
            ),
            child: Text(
              '${(inferenceTime ?? 0).toStringAsFixed(1)} ms  -  ${(fpsRate ?? 0).toStringAsFixed(1)} FPS',
              style: const TextStyle(color: Colors.white70),
            )),
      ),
    );
  }
}