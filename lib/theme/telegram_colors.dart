import 'package:flutter/material.dart';

class TelegramColors {
  // Основные цвета
  static const Color primary = Color(0xFF0088CC); // Lochmara (синий)
  static const Color primaryVariant = Color(0xFF2AABEE); // Альтернативный синий
  static const Color primaryDark = Color(0xFF229ED9); // Более насыщённый синий

  // Дополнительные цвета
  static const Color accent = Color(0xFFA19679); // Donkey Brown
  static const Color background = Color(0xFFFFFFFF); // Белый фон

  // Цвета для чатов
  static const Color chatBackground = Color(0xFFFFFFFF);
  static const Color messageBackground = Color(0xFFF1F1F1);
  static const Color unreadBadge = Color(0xFF0088CC);
  static const Color onlineIndicator = Color(0xFF4DDB5A);
  // Новые цвета пузырей сообщений (приближенно как на скриншоте)
  static const Color messageIncoming = Color(0xFFFFFFFF); // белый для входящих
  static const Color messageOutgoing = Color(0xFFD9FDD3); // мягкий зелёный для исходящих
  static const Color messageShadow = Color(0x1A000000); // чёрный с низкой непрозрачностью

  // Текстовые цвета
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFC7C7CC);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Статусные цвета
  static const Color divider = Color(0xFFE1E1E1);
  static const Color ripple = Color(0x1F0088CC);

  // AppBar
  static const Color appBarBackground = Color(0xFF0088CC);
  static const Color appBarText = Color(0xFFFFFFFF);

  // Системные цвета
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
} 