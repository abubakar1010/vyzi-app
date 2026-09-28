// import 'package:vyzi/core/utils/app_colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';
//
// class CustomPinCodeTextField extends StatelessWidget {
//   const CustomPinCodeTextField({super.key, this.textEditingController});
//   final TextEditingController? textEditingController;
//
//   @override
//   Widget build(BuildContext context) {
//     return PinCodeTextField(
//       appContext: context,
//       length: 6,
//       controller: textEditingController,
//       onChanged: (value) {
//         // textEditingController is already updated by the package if provided
//       },
//       onCompleted: (value) {
//         // Handle completion if needed
//       },
//       pinTheme: PinTheme(
//         shape: PinCodeFieldShape.box,
//         fieldHeight: 60.h,
//         fieldWidth: 47.w,
//         borderRadius: BorderRadius.circular(4.r),
//         borderWidth: 1,
//         activeColor: AppColors.primaryButton,
//         selectedColor: AppColors.primaryButton,
//         inactiveColor: Colors.grey,
//         activeFillColor: Colors.white,
//       ),
//       keyboardType: TextInputType.number,
//       textStyle: GoogleFonts.poppins(
//         fontSize: 22.sp,
//         color: Colors.black,
//         fontWeight: FontWeight.w600,
//       ),
//     );
//   }
// }
