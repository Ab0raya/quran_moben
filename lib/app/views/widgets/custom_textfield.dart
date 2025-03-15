import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../utils/colors.dart';
import '../../../utils/extensions.dart';
import 'glass_container.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.onChanged,
    required this.hint,
    this.icon,
    this.textInputType,
    this.color,
    this.controller,
    this.suffixIcon,
    this.validator,
    required this.obscureText,
    this.width,
    this.height,
  });

  final Function(String) onChanged;
  final String hint;
  final IconData? icon;
  final Widget? suffixIcon;
  final TextInputType? textInputType;
  final Color? color;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? screenHeight(context) * 0.07,
      width: width ?? screenWidth(context) * 0.9,
      child: GlassContainer(
        borderRadius: 12,
        height: screenHeight(context) * 0.07,
        width: screenWidth(context) * 0.9,
        verticalPadding: 10,
        horizontalPadding: 10,
        child: TextFormField(
          obscureText: obscureText,
          validator: validator,
          controller: controller,
          keyboardType: textInputType ?? TextInputType.text,
          onChanged: onChanged,
          style: TextStyle(color: color ?? AppColors.accentColor),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon ?? CupertinoIcons.search,
              color: color?.withOpacity(0.6) ??
                  AppColors.accentColor.withOpacity(0.6),
            ),
            suffixIcon: suffixIcon,
            hintText: hint,
            hintStyle: TextStyle(
              color: color?.withOpacity(0.6) ??
                  AppColors.accentColor.withOpacity(0.6),
              fontSize: 20,
            ),
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            errorStyle: const TextStyle(
              color: Colors.red,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}