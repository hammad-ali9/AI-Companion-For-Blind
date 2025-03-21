import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ultralytics_yolo_example/firebase_options.dart';
import 'package:ultralytics_yolo_example/providers/loading-provider.dart';
import 'package:ultralytics_yolo_example/utils/constants/fonts.dart';
import 'package:ultralytics_yolo_example/utils/constants/load-assets.dart';
import 'package:ultralytics_yolo_example/utils/routes/app-routes.dart';
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';
import 'package:ultralytics_yolo_example/view/direction/camera-view.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await preloadImages();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus!.unfocus();
          },
          child: MaterialApp(
            title: 'Path Vision',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                useMaterial3: true,
                fontFamily: AppFonts.monserrat),
            // home: CameraView(),
            initialRoute: RoutesNames.splashView,
            onGenerateRoute: Routes.generateRoute,
          ),
        ),
      ),
    );
  }
}


// import 'dart:io' as io;

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:path/path.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:ultralytics_yolo/ultralytics_yolo.dart';
// import 'package:ultralytics_yolo/yolo_model.dart';

// void main() {
//   runApp(const CameraView());
// }

// class CameraView extends StatefulWidget {
//   const CameraView({super.key});

//   @override
//   State<CameraView> createState() => _MyAppState();
// }

// class _MyAppState extends State<CameraView> {
//   final controller = UltralyticsYoloCameraController();

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: FutureBuilder<bool>(
//           future: _checkPermissions(),
//           builder: (context, snapshot) {
//             final allPermissionsGranted = snapshot.data ?? false;

//             return !allPermissionsGranted
//                 ? const Center(
//               child: Text("Error requesting permissions"),
//             )
//                 : FutureBuilder<ObjectDetector>(
//               future: _initObjectDetectorWithLocalModel(),
//               builder: (context, snapshot) {
//                 final predictor = snapshot.data;

//                 return predictor == null
//                     ? Container()
//                     : Stack(
//                   children: [
//                     UltralyticsYoloCameraPreview(
//                       controller: controller,
//                       predictor: predictor,
//                       onCameraCreated: () {
//                         predictor.loadModel(useGpu: true);
//                       },
//                     ),
//                     StreamBuilder<double?>(
//                       stream: predictor.inferenceTime,
//                       builder: (context, snapshot) {
//                         final inferenceTime = snapshot.data;

//                         return StreamBuilder<double?>(
//                           stream: predictor.fpsRate,
//                           builder: (context, snapshot) {
//                             final fpsRate = snapshot.data;

//                             return Times(
//                               inferenceTime: inferenceTime,
//                               fpsRate: fpsRate,
//                             );
//                           },
//                         );
//                       },
//                     ),
//                   ],
//                 );
//               },
//             );
//           },
//         ),
//         floatingActionButton: FloatingActionButton(
//           child: const Icon(Icons.cameraswitch),
//           onPressed: () {
//             controller.toggleLensDirection();
//           },
//         ),
//       ),
//     );
//   }

//   Future<ObjectDetector> _initObjectDetectorWithLocalModel() async {
//     // FOR IOS
//     // final modelPath = await _copy('assets/yolov8n.mlmodel');
//     // final model = LocalYoloModel(
//     //   id: '',
//     //   task: Task.detect,
//     //   format: Format.coreml,
//     //   modelPath: modelPath,
//     // );
//     // FOR ANDROID
//     final modelPath = await _copy('assets/yolov8n_int8.tflite');
//     final metadataPath = await _copy('assets/metadata.yaml');
//     final model = LocalYoloModel(
//       id: '',
//       task: Task.detect,
//       format: Format.tflite,
//       modelPath: modelPath,
//       metadataPath: metadataPath,
//     );

//     return ObjectDetector(model: model);
//   }

//   // Future<ImageClassifier> _initImageClassifierWithLocalModel() async {
//   //   final modelPath = await _copy('assets/yolov8n-cls.mlmodel');
//   //   final model = LocalYoloModel(
//   //     id: '',
//   //     task: Task.classify,
//   //     format: Format.coreml,
//   //     modelPath: modelPath,
//   //   );

//   //   final modelPath = await _copy('assets/yolov8n-cls.bin');
//   //   final paramPath = await _copy('assets/yolov8n-cls.param');
//   //   final metadataPath = await _copy('assets/metadata-cls.yaml');
//   //   final model = LocalYoloModel(
//   //     id: '',
//   //     task: Task.classify,
//   //     modelPath: modelPath,
//   //     paramPath: paramPath,
//   //     metadataPath: metadataPath,
//   //   );

//   //   return ImageClassifier(model: model);
//   // }

//   Future<String> _copy(String assetPath) async {
//     final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
//     await io.Directory(dirname(path)).create(recursive: true);
//     final file = io.File(path);
//     if (!await file.exists()) {
//       final byteData = await rootBundle.load(assetPath);
//       await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
//     }
//     return file.path;
//   }

//   Future<bool> _checkPermissions() async {
//     List<Permission> permissions = [];

//     var cameraStatus = await Permission.camera.status;
//     if (!cameraStatus.isGranted) permissions.add(Permission.camera);

//     var storageStatus = await Permission.photos.status;
//     if (!storageStatus.isGranted) permissions.add(Permission.photos);

//     if (permissions.isEmpty) {
//       return true;
//     } else {
//       try {
//         Map<Permission, PermissionStatus> statuses = await permissions.request();
//         return statuses.values.every((status) => status == PermissionStatus.granted);
//       } on Exception catch (_) {
//         return false;
//       }
//     }
//   }
// }

// class Times extends StatelessWidget {
//   const Times({
//     super.key,
//     required this.inferenceTime,
//     required this.fpsRate,
//   });

//   final double? inferenceTime;
//   final double? fpsRate;

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Align(
//         alignment: Alignment.bottomCenter,
//         child: Container(
//             margin: const EdgeInsets.all(20),
//             padding: const EdgeInsets.all(20),
//             decoration: const BoxDecoration(
//               borderRadius: BorderRadius.all(Radius.circular(10)),
//               color: Colors.black54,
//             ),
//             child: Text(
//               '${(inferenceTime ?? 0).toStringAsFixed(1)} ms  -  ${(fpsRate ?? 0).toStringAsFixed(1)} FPS',
//               style: const TextStyle(color: Colors.white70),
//             )),
//       ),
//     );
//   }
// }