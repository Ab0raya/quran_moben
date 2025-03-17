import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
     this.height,
    this.width,
    required this.child,
    this.horizontalPadding,
    this.verticalPadding,
    this.borderRadius,
    this.virMargin,
    this.horMargin,
    this.onTap,
    this.align,
    this.color, this.border,
  });

  final double? height;
  final double? width;
  final Widget child;
  final double? horizontalPadding;

  final double? verticalPadding;
  final Function()? onTap;

  final double? borderRadius;

  final double? virMargin;

  final double? horMargin;
  final AlignmentGeometry? align;
  final Color? color;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:  EdgeInsets.symmetric(
          vertical: virMargin ?? 0, horizontal: horMargin ?? 0),
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 15)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            alignment: align,
            padding: EdgeInsets.symmetric(
                vertical: verticalPadding ?? 0,
                horizontal: horizontalPadding ?? 0),
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color ?? Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.all(
                Radius.circular(borderRadius ?? 15),
              ),
              border: border,
            ),
            child: InkWell(
              borderRadius: BorderRadius.all(Radius.circular(borderRadius ?? 15)),
              onTap: onTap,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}