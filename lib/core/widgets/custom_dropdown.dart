// import 'package:event_sharing/utils/app_colors.dart';
// import 'package:event_sharing/utils/app_icons.dart';
// import 'package:event_sharing/utils/style.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
//
// class CustomDropdown extends StatelessWidget {
//   final List<String> items;
//   final String? selectedValue;
//   final String hintText;
//   final Function(String?) onChanged;
//   final Color fillColor;
//   final Color borderColor;
//   final double height;
//
//   const CustomDropdown({
//     Key? key,
//     required this.items,
//     required this.selectedValue,
//     required this.hintText,
//     required this.onChanged,
//     required this.fillColor,
//     required this.borderColor,
//     this.height = 54, // Default height
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: height == 54 ? AppStyles.standardHeight : height.h,
//       child: InputDecorator(
//         decoration: InputDecoration(
//           fillColor: fillColor,
//           filled: true,
//           border: OutlineInputBorder(
//             borderSide: BorderSide(color: borderColor, width: 1.w),
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: borderColor, width: 1.w),
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: borderColor, width: 1.w),
//             borderRadius: BorderRadius.circular(8.r),
//           ),
//           contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
//         ),
//         child: DropdownButtonHideUnderline(
//           child: DropdownButton<String>(
//             iconDisabledColor: borderColor,
//             icon: SvgPicture.asset(AppIcons.down_ArrowIcon,color: AppColors.primaryColor,height: 8.h),
//             iconEnabledColor: borderColor,
//             isExpanded: true,
//             value: selectedValue,
//             hint: Text(hintText, style: TextStyle(fontSize: 14.sp)),
//             items: items.map((String value) {
//               return DropdownMenuItem<String>(
//                 value: value,
//                 child: Text(value),
//               );
//             }).toList(),
//             onChanged: onChanged,
//           ),
//         ),
//       ),
//     );
//   }
// }
//

