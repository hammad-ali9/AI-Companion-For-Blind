import 'package:flutter/material.dart';
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';
import 'package:ultralytics_yolo_example/view/arrived/arrived-view.dart';
import 'package:ultralytics_yolo_example/view/auth/register-view.dart';
import 'package:ultralytics_yolo_example/view/direction/camera-view.dart';
import 'package:ultralytics_yolo_example/view/direction/start-direction-view.dart';
import 'package:ultralytics_yolo_example/view/home/home-view.dart';
import 'package:ultralytics_yolo_example/view/setting/profile-setting-view.dart';
import 'package:ultralytics_yolo_example/view/welcome/welcome-view.dart';

import '../../view/splash/splash-view.dart';

class Routes {
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case RoutesNames.splashView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const SplashView());
      case RoutesNames.welcomeView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const WelcomeView());
      case RoutesNames.registerView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const RegisterView());
      case RoutesNames.homeView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const HomeView());
      case RoutesNames.startDirectionView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const StartDirectionView());
      case RoutesNames.arrivedView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const ArrivedView());
      case RoutesNames.profileSettingView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const ProfileSettingView());
      case RoutesNames.cameraView:
        return MaterialPageRoute(
            builder: (BuildContext context) => const CameraView(),
            settings: routeSettings);
      default:
        return MaterialPageRoute(builder: (_) {
          return const Scaffold(
            body: Center(
              child: Text('No routes defined'),
            ),
          );
        });
    }
  }
}
