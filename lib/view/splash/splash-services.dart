import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../utils/routes/routes-name.dart';

class SplashServices{

  void isLoggedIn(BuildContext context){
    Timer(const Duration(seconds: 3), () => Navigator.pushNamedAndRemoveUntil(context,RoutesNames.welcomeView,(route) => false,));
  }


}