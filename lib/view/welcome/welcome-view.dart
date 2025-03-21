import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo_example/utils/extensions/sizebox.dart';
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:ultralytics_yolo_example/utils/constants/app-assets.dart';
import 'package:ultralytics_yolo_example/utils/constants/colors.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/round-button.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  WelcomeViewState createState() => WelcomeViewState();
}

class WelcomeViewState extends State<WelcomeView>
    with SingleTickerProviderStateMixin {
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();
  bool isListening = false;
  String recognizedText = "";
  Timer? _silenceTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    config();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.5).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  config() async {
    await speak(
        "'Increase your target to be healthier to continue exercising' Say 'get started' to get start");
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
          onResult: (result) {
            setState(() {
              recognizedText = result.recognizedWords;
            });
            _resetSilenceTimer();

            if (recognizedText.toLowerCase() == 'get started') {
              stopListening();
              Navigator.pushNamed(context, RoutesNames.registerView);
            }
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
    setState(() {
      isListening = false;
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 3), () {
      stopListening();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
                color: blackColor,
                image: DecorationImage(
                    image: AssetImage(AppAssets.girlBgIcon),
                    fit: BoxFit.cover)),
          ),
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      color: whiteColor.withOpacity(0.2)),
                  child: Padding(
                    padding: EdgeInsets.all(14.sp),
                    child: Column(
                      children: [
                        Text(
                          "Increase your target to be healthier to continue exercising",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.zenDots(
                              fontSize: 26.sp,
                              fontWeight: FontWeight.w400,
                              color: whiteColor,
                              height: 1.5),
                        ),
                        30.height,
                        RoundButton(
                            borderRadius: BorderRadius.circular(50.r),
                            isShowIcon: true,
                            title: "Speak to Get Started",
                            onTap: () {
                              speak("Say 'get started' to get start");
                            }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isListening)
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
        ],
      ),
    );
  }
}
