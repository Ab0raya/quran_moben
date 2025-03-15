import 'package:flutter/material.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/extensions.dart';

class LastReadCard extends StatelessWidget {
  final String surahName;
  final String ayahNumber;
  final VoidCallback onTap;


  const LastReadCard({
    super.key,
    required this.surahName,
    required this.ayahNumber, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: screenHeight(context)*0.14,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.secAccentColor, AppColors.accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        const Icon(Icons.book, color: AppColors.bgColor),
                        (screenWidth(context)*0.01).sw,
                        const Text(
                          'آخر قراءة',
                          style: TextStyle(
                            color: AppColors.bgColor,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      surahName,
                      style: const TextStyle(
                        color: AppColors.bgColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'آية رقم: $ayahNumber',
                      style: const TextStyle(
                        color: AppColors.bgColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),

            Image.asset(
              'assets/images/quran_book.png',
              width: screenWidth(context)*0.3,
              fit: BoxFit.contain,
            ),

          ],
        ),
      ),
    );
  }
}
