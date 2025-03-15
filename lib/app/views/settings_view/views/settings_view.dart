import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quran_moben/app/views/widgets/custom_textfield.dart';
import 'package:quran_moben/app/views/widgets/glass_container.dart';
import 'package:quran_moben/utils/colors.dart';
import 'package:quran_moben/utils/extensions.dart';

import '../../../controllers/home_controller.dart';
import '../../../controllers/quran_page_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final HomeController controller = Get.put(HomeController());
  final TextEditingController _nameController = TextEditingController();
  final QuranPageController quranPageController =
      Get.put(QuranPageController());

  @override
  void initState() {
    super.initState();
    _nameController.text = controller.savedName.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: AppBar(
        title: const Text('الإعدادات'),
        backgroundColor: AppColors.bgColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNameInputSection(),
            const SizedBox(height: 20),
            _buildThemeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInputSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            height: screenHeight(context) * 0.06,
            width: screenWidth(context) * 08,
            onChanged: (c) {},
            hint: 'أدخل أسمك',
            obscureText: false,
            controller: _nameController,
            suffixIcon: IconButton(
              icon:
                  const Icon(Icons.check_circle, color: AppColors.accentColor),
              onPressed: () => controller.saveName(_nameController.text),
            ),
            icon: Icons.person,
          ),
          if (controller.hasName.value)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'الاسم المحفوظ: ${controller.savedName.value}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildThemeSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'اختيار الثيم',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _buildThemeOption(
            title: 'الوضع النهاري',
            icon: Icons.light_mode,
            isSelected: quranPageController.selectedTabIndex.value == 0,
            onTap: () {
              quranPageController.changeTab(0);
              quranPageController.setLightTheme();
            },
          ),
          _buildThemeOption(
            title: 'الوضع الليلي',
            icon: Icons.dark_mode,
            isSelected: quranPageController.selectedTabIndex.value == 1,
            onTap: () {
              quranPageController.changeTab(1);
              quranPageController.setDarkTheme();
            },
          ),
          _buildThemeOption(
            title: 'وضع سيبيا',
            icon: Icons.color_lens,
            isSelected: quranPageController.selectedTabIndex.value == 2,
            onTap: () {
              quranPageController.changeTab(2);
              quranPageController.setSepiaTone();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GlassContainer(
      height: screenHeight(context) * 0.06,
      width: screenWidth(context) * 08,
      virMargin: screenHeight(context) * 0.01,
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentColor),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.accentColor),
        ),
        trailing: isSelected
            ? const Icon(Icons.check, color: AppColors.accentColor)
            : null,
        onTap: onTap,
      ),
    );
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: isSelected
            ? const Icon(Icons.check, color: AppColors.accentColor)
            : null,
        onTap: onTap,
      ),
    );
  }
}
