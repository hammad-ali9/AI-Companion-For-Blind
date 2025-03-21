import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PopButtton extends StatelessWidget {
  const PopButtton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xffD8DADC))),
        child: const Center(
          child: Icon(Icons.arrow_back_rounded),
        ),
      ),
    );
  }
}
