import 'package:flutter/material.dart';
import '../theme/telegram_colors.dart';

class AvatarCircle extends StatelessWidget {
  final String title;
  final double size;
  final bool showOnline;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? letterColor;

  const AvatarCircle({
    super.key,
    required this.title,
    this.size = 36,
    this.showOnline = false,
    this.onTap,
    this.gradient,
    this.backgroundColor,
    this.letterColor,
  });

  static Gradient gradientFor(String seed, {double saturation = 0.65, double lightness = 0.55}) {
    final hash = seed.isNotEmpty ? seed.codeUnitAt(0) : 0;
    final hue = (hash * 37) % 360;
    final hue2 = (hue + 24) % 360;
    final c1 = HSLColor.fromAHSL(1, hue.toDouble(), saturation, lightness).toColor();
    final c2 = HSLColor.fromAHSL(1, hue2.toDouble(), saturation, lightness).toColor();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c1, c2],
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? TelegramColors.messageBackground,
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: TelegramColors.messageShadow, blurRadius: 2, offset: Offset(0, 1)),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: size * 0.45,
            color: letterColor ?? (gradient != null ? Colors.white : TelegramColors.textPrimary),
          ),
        ),
      ),
    );

    if (showOnline) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                color: TelegramColors.onlineIndicator,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      avatar = InkWell(onTap: onTap, customBorder: const CircleBorder(), child: avatar);
    }

    return avatar;
  }
} 