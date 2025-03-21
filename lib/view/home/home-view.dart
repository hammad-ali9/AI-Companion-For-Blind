import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:ultralytics_yolo_example/utils/constants/colors.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/my-text.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/round-button.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/text-field.dart';
import 'package:ultralytics_yolo_example/utils/extensions/sizebox.dart';
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';
import 'package:ultralytics_yolo_example/view/home/maps.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
  final TextEditingController _currentAddress = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();
  bool isListening = false;
  Timer? _silenceTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(0.7);
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
    await startListening();
  }

  Future<void> startListening() async {
    try {
      bool available = await speechToText.initialize();
      if (available) {
        setState(() {
          isListening = true;
        });
        _animationController.repeat(reverse: true);

        speechToText.listen(
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 3),
          partialResults: false,
          onResult: (result) async {
            setState(() {
              _destinationController.text = result.recognizedWords;
            });
          },
          onSoundLevelChange: (level) {
            if (level < 0.1) {
              _resetSilenceTimer();
            }
          },
        );
      } else {
        speak("Speech recognition is not available.");
      }
    } catch (e) {
      speak("Error initializing speech recognition: $e");
    }
  }

  void stopListening() {
    speechToText.stop();
    _silenceTimer?.cancel();
    _animationController.stop();
    setState(() => isListening = false);
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), stopListening);
  }

  @override
  void dispose() {
    _animationController.dispose();
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMaps(
            onLocationFetched: (address) {
              setState(() {
                _currentAddress.text = address;
                speak(
                    'Your current location is $address. Where do you want to go?');
              });
            },
            destinationAddress: _destinationController.text,
            flutterTts: flutterTts, // Pass FlutterTts to GoogleMaps
          ),
          _buildDraggableBottomSheet(context),
          Positioned(
            top: 45.h,
            right: 50.w,
            child: GestureDetector(
              onTap: () =>
                  Navigator.pushNamed(context, RoutesNames.profileSettingView),
              child: Image.asset('assets/images/settings.png'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableBottomSheet(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.12,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              Container(
                height: 40.h,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.horizontal_rule_rounded,
                  color: primaryColor,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        15.height,
                        _buildCurrentLocationField(),
                        15.height,
                        _buildDestinationField(),
                        15.height,
                        _buildListeningIndicator(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MyText(
              text: "Set Route",
              fontWeight: FontWeight.w600,
              size: 16.sp,
              color: darkGreyColor,
            ),
            MyText(
              text: "Speak to set your route",
              fontWeight: FontWeight.w400,
              size: 10.sp,
              color: blackColor.withOpacity(0.5),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await startListening();
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: greyColor),
              borderRadius: BorderRadius.circular(29.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
            child: Image.asset(
              'assets/images/micIcon.png',
              color: primaryColor,
              width: 14.w,
              height: 14.h,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildCurrentLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: "Current",
          fontWeight: FontWeight.w400,
          size: 14.sp,
        ),
        5.height,
        CustomTextFiled(
          hintText: "Your Current Location Goes Here",
          controller: _currentAddress,
          isShowPrefixImage: false,
          isShowPrefixIcon: false,
          isFilled: true,
          isBorder: true,
          borderRadius: 10.r,
        ),
      ],
    );
  }

  Widget _buildDestinationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyText(
          text: "To",
          fontWeight: FontWeight.w400,
          size: 14.sp,
        ),
        5.height,
        CustomTextFiled(
          hintText: "Your Location Goes Here",
          controller: _destinationController,
          isShowPrefixImage: false,
          isShowPrefixIcon: false,
          isFilled: true,
          isBorder: true,
          borderRadius: 10.r,
        ),
      ],
    );
  }

  Widget _buildListeningIndicator() {
    return Center(
      child: Column(
        children: [
          if (isListening) ...[
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: ScaleTransition(
                  scale: _animation,
                  child: Image.asset(
                    'assets/images/mic.png',
                    width: 80.w,
                    height: 80.h,
                  ),
                ),
              ),
            ),
            5.height,
            MyText(
              text: "Please Speak..",
              fontWeight: FontWeight.w500,
              size: 16.sp,
              color: darkGreyColor,
            ),
          ],
        ],
      ),
    );
  }
}
