import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ultralytics_yolo_example/main.dart';
import 'package:ultralytics_yolo_example/utils/constants/app-assets.dart';
import 'package:ultralytics_yolo_example/utils/constants/colors.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/my-text.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/round-button.dart';
import 'package:ultralytics_yolo_example/utils/extensions/sizebox.dart';
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';
import 'package:ultralytics_yolo_example/view/splash/splash-services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import the permission_handler package

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    config();
    // SplashServices().isLoggedIn(context);
  }

  Future<void> config() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? name = prefs.getString('name');
    if (name != null) {
      await Future.delayed(const Duration(seconds: 3)).whenComplete(() async {
        await requestMicrophonePermission().then((val) async {
          await requestLocationPermission().then((v) async {
            await requestCameraPermission();
          });
        });

        Navigator.pushReplacementNamed(context, RoutesNames.homeView);
      });
    } else {
      await Future.delayed(const Duration(seconds: 3)).whenComplete(() async {
        await requestMicrophonePermission().then((val) async {
          await requestLocationPermission().then((v) async {
            await requestCameraPermission();
          });
        });
      });
      Navigator.pushReplacementNamed(context, RoutesNames.welcomeView);
    }
  }

  Future<void> requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> requestMicrophonePermission() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Center(child: Image.asset(AppAssets.appIcon, scale: 3)),
          5.height,
          MyText(
            text: "PATH VISION",
            color: const Color(0xff2E3C45),
            fontWeight: FontWeight.w800,
            size: 19.sp,
          ),
          const Spacer(),
          SpinKitCircle(
            color: primaryColor,
            size: 50.sp,
          ),
          10.height,
        ],
      ),
    );
  }
}
