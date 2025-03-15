import 'package:flutter/material.dart';
import 'package:quran_moben/utils/extensions.dart';
import '../../../../utils/colors.dart';

class SurahTile extends StatelessWidget {
  final int number;
  final String name;
  final String origin;
  final int versesCount;
  final VoidCallback onTap;

  const SurahTile({
    super.key,
    required this.number,
    required this.name,
    required this.origin,
    required this.versesCount, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.accentColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.accentColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            (screenWidth(context)*0.03).sw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                 (screenHeight(context)*0.003).sh,
                  Text(
                    origin == 'meccan' ? 'مكية • $versesCount' :'مدنية • $versesCount' ,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}