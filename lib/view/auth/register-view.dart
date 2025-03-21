import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/my-text.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/pop_buttton.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/round-button.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/symetric-padding.dart';
import 'package:ultralytics_yolo_example/utils/customWidgets/text-field.dart';
import 'package:ultralytics_yolo_example/utils/extensions/sizebox.dart';
import 'package:ultralytics_yolo_example/utils/routes/routes-name.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../utils/constants/colors.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView>
    with SingleTickerProviderStateMixin {
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
    await speak("Register to get started, What's your name?");
    await startListening();
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
          listenFor: const Duration(minutes: 2), // Keep listening for longer
          pauseFor:
              const Duration(seconds: 2), // Silence timeout (adjust as needed)
          partialResults:
              false, // Enable partial results to capture ongoing speech
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
            "Thank you for providing your details. say 'register' to continue");
        // Proceed to registration or next step

        break;

      case 3:
        print(input.toLowerCase());
        if (input.toLowerCase() == 'register' && nameController.text != '') {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('name', nameController.text);
          await prefs.setString('email', emailController.text);
          await prefs.setString('phone', phoneController.text);
          Navigator.pushNamed(context, RoutesNames.homeView);
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
                  const PopButtton(),
                  50.height,
                  FittedBox(
                      fit: BoxFit.scaleDown,
                      child: MyText(
                        text: "Register to get started",
                        size: 28.sp,
                        fontWeight: FontWeight.w700,
                      )),
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
                  20.height,
                  RoundButton(
                      title: "Register",
                      onTap: () async {
                        setState(() {
                          currentStep = 3;
                        });
                        await speak('say register to continue');
                        await startListening();
                      }),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyText(
                        text: "Already have an account? ",
                        fontWeight: FontWeight.w400,
                        size: 14.sp,
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, RoutesNames.homeView);
                        },
                        child: MyText(
                          text: "Go Home",
                          fontWeight: FontWeight.w800,
                          size: 14.sp,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  20.height
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
