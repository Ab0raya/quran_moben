import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_moben/utils/extensions.dart';
import '../../../../utils/colors.dart';
import '../../../controllers/home_controller.dart';

class CustomTabBar extends StatelessWidget {
  final HomeController controller;

  const CustomTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Column(
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            _buildTab(0, 'سورة', context),
            _buildTab(1, 'جزء', context),
            _buildTab(2, 'ختمه', context),
          ],
        ),
        Container(
          height: 3,
          color: AppColors.bgColor,
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              for (int i = 0; i < 3; i++)
                Expanded(
                  child: Container(
                    color: controller.selectedTabIndex.value == i
                        ? AppColors.accentColor
                        : Colors.transparent,
                  ),
                ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildTab(int index, String text, BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.changeTab(index),
        child: Container(
          height: screenHeight(context) * 0.05,
          color: Colors.transparent,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: controller.selectedTabIndex.value == index
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight: controller.selectedTabIndex.value == index
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
