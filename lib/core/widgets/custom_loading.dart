import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return  SizedBox(
      height: 20.h,
      width: 20.h,
      child: const CircularProgressIndicator(color: Colors.white,),
    );
  }
}
