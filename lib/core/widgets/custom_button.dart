import 'package:flutter/material.dart';
import '../constants/app_colors.dart';


class CustomButton extends StatelessWidget {

  final bool isCenter;
  final double? buttonWidth;
  final double? buttonHeight;
  final Color? buttonColor;
  final double? buttonBorderRad;
  final Color? buttonBorderColor;
  final double? borderWidth;
  final Widget? icon;
  final String title;
  final VoidCallback? onTap;
  final double? titleSize;
  final Color? titleColor;
  final FontWeight? titleWeight;



  const CustomButton({
    super.key,
    required this.isCenter,
    required this.title,
    this.onTap,
    this.titleSize,
    this.titleColor,
    this.icon,
    this.buttonWidth,
    this.buttonHeight,
    this.buttonColor,
    this.buttonBorderRad,
    this.buttonBorderColor,
    this.borderWidth,
    this.titleWeight,
  });



  @override
  Widget build(BuildContext context) {

    return Container(
      height: buttonHeight ?? 50,
      width: buttonWidth ?? double.infinity,

      decoration: BoxDecoration(
        color: buttonColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(buttonBorderRad ?? 15),
        border: Border.all(color: buttonBorderColor ?? AppColors.primaryBlueDark, width: borderWidth ?? 2),

        boxShadow: [
          BoxShadow(
            color: AppColors.greyDark.withOpacity(0.2),
            blurRadius: 7,
            spreadRadius: 0.3,
            offset: Offset(-0.5, 3.3),
          ),
        ],
      ),


      child: InkWell(
        onTap: onTap,

        // Icon & Title
        child: Row(
          mainAxisAlignment: isCenter ? MainAxisAlignment.center : MainAxisAlignment.start,

          children: [
            // Icon
            icon ?? SizedBox(width: 0, height: 0,),

            icon == null ? SizedBox(width: 0, height: 0,) : const SizedBox(width: 10.0),

            // Title & Subtitle
            Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: titleSize,
                    fontWeight: titleWeight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}