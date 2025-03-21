import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/pop_buttton.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/symetric-padding.dart';
import 'package:ultralytics_yolo_example/utils/extensions/global-functions.dart';
import 'package:ultralytics_yolo_example/utils/extensions/sizebox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../utils/constants/colors.dart';
import '../../utils/customWidgets/my-text.dart';
import '../../utils/customWidgets/round-button.dart';
import '../../utils/customWidgets/text-field.dart';

class ProfileSettingView extends StatefulWidget {
  const ProfileSettingView({super.key});

  @override
  State<ProfileSettingView> createState() => _ProfileSettingViewState();
}

class _ProfileSettingViewState extends State<ProfileSettingView>
    with SingleTickerProviderStateMixin {
  // double _currentVolume = 20; // Initial volume value
  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText speechToText = SpeechToText();
  bool isListening = false;
  String recognizedText = "";
  Timer? _silenceTimer;
  late AnimationController _animationController;
  late Animation<double> _animation;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  int currentStep = 0; // Track the current step (username, email, phone)

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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString('name') != null) {
      nameController.text = prefs.getString('name')!;
    }
    if (prefs.getString('email') != null) {
      emailController.text = prefs.getString('email')!;
    }
    if (prefs.getString('phone') != null) {
      phoneController.text = prefs.getString('phone')!;
    }
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setPitch(0.7);
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak(text);
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
          listenFor: const Duration(minutes: 1), // Keep listening for longer
          pauseFor:
              const Duration(seconds: 2), // Silence timeout (adjust as needed)
          partialResults:
              true, // Enable partial results to capture ongoing speech
          onResult: (result) async {
            setState(() {
              recognizedText = result.recognizedWords;
            });

            // If the user pauses, consider it the end of their input
            if (result.finalResult) {
              stopListening();
              handleVoiceInput(recognizedText);
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

  Future<void> handleVoiceInput(String input) async {
    switch (currentStep) {
      case 0: // Step for Name
        // Split input into words to check for multi-word names

        final words = input.split(' ');
        if (words.length > 1) {
          nameController.text = input; // Use full input as the name
        } else {
          nameController.text = input; // Single word is the name
        }
        currentStep++;
        await speak("What's your email?");
        break;

      case 1: // Step for Email
        emailController.text = input.replaceAll(' ', '');
        currentStep++;
        await speak("What's your phone number?");

        break;

      case 2: // Step for Phone

        phoneController.text = input.replaceAll(' ', '');
        currentStep++;
        await speak(
            "Thank you for providing your details. say 'done' to continue");
        // Proceed to registration or next step

        break;

      case 3:
        if (input.toLowerCase() == 'done' && nameController.text != '') {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', nameController.text);
          await prefs.setString('email', emailController.text);
          await prefs.setString('phone', phoneController.text);
          Navigator.pop(context);
        }
    }

    recognizedText = ""; // Clear recognized text after processing

    // Start listening for the next input if not at the last step
    if (currentStep <= 3) {
      await startListening();
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
      backgroundColor: whiteColor,
      resizeToAvoidBottomInset: false,
      body: SymmetricPadding(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  50.height,
                  Row(
                    children: [
                      const PopButtton(),
                      const Spacer(),
                      MyText(
                        text: "Profile Setting",
                        fontWeight: FontWeight.w600,
                        size: 16.sp,
                      ),
                      const Spacer()
                    ],
                  ),
                  50.height,
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        currentStep = 0;
                      });
                      await speak("What's your name?");
                      await startListening();
                    },
                    child: MyText(
                        text: "Username",
                        fontWeight: FontWeight.w400,
                        size: 14.sp),
                  ),
                  5.height,
                  CustomTextFiled(
                    hintText: "Your username",
                    isShowPrefixImage: false,
                    isShowPrefixIcon: false,
                    isFilled: true,
                    isBorder: true,
                    borderRadius: 10.r,
                    controller: nameController,
                  ),
                  15.height,
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        currentStep = 1;
                      });
                      await speak("What's your email?");
                      await startListening();
                    },
                    child: MyText(
                        text: "Email",
                        fontWeight: FontWeight.w400,
                        size: 14.sp),
                  ),
                  5.height,
                  CustomTextFiled(
                    hintText: "example@gmail",
                    isShowPrefixImage: false,
                    isShowPrefixIcon: false,
                    isFilled: true,
                    isBorder: true,
                    borderRadius: 10.r,
                    controller: emailController,
                  ),
                  15.height,
                  GestureDetector(
                    onTap: () async {
                      setState(() {
                        currentStep = 2;
                      });
                      await speak("What's your phone number?");
                      await startListening();
                    },
                    child: MyText(
                        text: "Phone Number",
                        fontWeight: FontWeight.w400,
                        size: 14.sp),
                  ),
                  5.height,
                  CustomTextFiled(
                    hintText: "+923217895131",
                    keyboardType: TextInputType.phone,
                    isShowPrefixImage: false,
                    isShowPrefixIcon: false,
                    isFilled: true,
                    isBorder: true,
                    borderRadius: 10.r,
                    controller: phoneController,
                  ),
                  15.height,
                  // MyText(
                  //     text: "Volume setting",
                  //     fontWeight: FontWeight.w400,
                  //     size: 14.sp),
                  // 5.height,
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //   children: [
                  //     // Slider
                  //     Expanded(
                  //       child: SliderTheme(
                  //         data: SliderThemeData(
                  //           trackHeight: 5,
                  //           thumbShape:
                  //               RoundSliderThumbShape(enabledThumbRadius: 12.r),
                  //           overlayShape:
                  //               RoundSliderOverlayShape(overlayRadius: 5.r),
                  //           activeTrackColor: primaryColor,
                  //           inactiveTrackColor: gradientColorTwo,
                  //           thumbColor: whiteColor,
                  //           overlayColor: gradientColorThree,
                  //         ),
                  //         child: Slider(
                  //           value: _currentVolume,
                  //           min: 0,
                  //           max: 100,
                  //           divisions: 100,
                  //           onChanged: (value) {
                  //             setState(() {
                  //               _currentVolume = value;
                  //             });
                  //           },
                  //         ),
                  //       ),
                  //     ),
                  //     10.width,
                  //     MyText(
                  //       text: "${_currentVolume.toInt()}%",
                  //       color: const Color(0xff524F4F),
                  //       size: 11.sp,
                  //       fontWeight: FontWeight.w600,
                  //     )
                  //   ],
                  // ),
                  20.height,
                  const Spacer(),
                  RoundButton(
                      title: "Save Change",
                      onTap: () async {
                        setState(() {
                          currentStep = 3;
                        });
                        await speak('say done to continue');
                        await startListening();
                      }),
                  10.height,
                  RoundButton(
                      title: "Discard",
                      bgColor: whiteColor,
                      borderColor: primaryColor,
                      textColor: primaryColor,
                      onTap: () async {
                        await speak('say cancel to get back');
                        bool available = await speechToText.initialize();
                        if (available) {
                          setState(() {
                            isListening = true;
                          });
                          _animationController.repeat(reverse: true);
                          speechToText.listen(
                            onResult: (result) {
                              setState(() {
                                recognizedText = result.recognizedWords;
                              });
                              _resetSilenceTimer();

                              if (recognizedText.toLowerCase() == 'cancel') {
                                stopListening();
                                Navigator.pop(context);
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
                        // Navigator.pop(context);
                      }),
                  10.height,
                ],
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
        ),
      ),
    );
  }
}
