import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({
    super.key,
    this.size = 56,
    this.radius = 18,
    this.padding = 6,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE8ECE8),
  });

  final double size;
  final double radius;
  final double padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(16, 24, 40, 0.06),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - padding),
        child: SvgPicture.asset(
          'assets/lii_logo.svg',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
