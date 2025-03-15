import 'package:flutter/material.dart';


class ActionButton extends StatelessWidget {
  const ActionButton({super.key, required this.icon, required this.label, required this.color, required this.onTap});

     final IconData icon;
     final String label;
     final Color color;
     final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
