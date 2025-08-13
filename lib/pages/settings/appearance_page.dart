import 'package:flutter/material.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

enum AppThemeMode { system, light, dark }

class _AppearancePageState extends State<AppearancePage> {
  int backgroundIndex = 0;
  AppThemeMode themeMode = AppThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Оформление', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _preview(),
          const SizedBox(height: 12),
          SettingsCard(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text('Фон', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  _bgOption(0, _bgDecoration0()),
                  const SizedBox(width: 16),
                  _bgOption(1, _bgDecoration1()),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          const SettingsSectionLabel('тема'),
          SettingsCard(children: [
            _themeTile(AppThemeMode.system, 'Системная', position: SettingsTilePosition.first),
            _themeTile(AppThemeMode.light, 'Светлая', position: SettingsTilePosition.middle),
            _themeTile(AppThemeMode.dark, 'Тёмная', position: SettingsTilePosition.last),
          ]),
        ],
      ),
    );
  }

  Widget _preview() {
    return Container(
      height: 180,
      decoration: backgroundIndex == 0 ? _bgDecoration0() : _bgDecoration1(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bubble('Привет, как дела?', alignment: Alignment.centerLeft, time: '14:02'),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _bubble('Привет! Хорошо, а у тебя?', alignment: Alignment.centerRight, outgoing: true, time: '14:02'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _bgDecoration0() {
    return BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF7AC6FF), Color(0xFF6AB6F9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
    );
  }

  BoxDecoration _bgDecoration1() {
    return BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFFA9E0FF), Color(0xFF7DC6E9), Color(0xFF7EB8FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(18),
    );
  }

  Widget _bubble(String text, {Alignment alignment = Alignment.centerLeft, bool outgoing = false, required String time}) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: outgoing ? const Color(0xFFD9FDD3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: Text(text, style: const TextStyle(fontSize: 15))),
            const SizedBox(width: 8),
            Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
          ],
        ),
      ),
    );
  }

  Widget _bgOption(int index, BoxDecoration decoration) {
    final bool isSelected = backgroundIndex == index;
    return GestureDetector(
      onTap: () => setState(() => backgroundIndex = index),
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: decoration.copyWith(borderRadius: BorderRadius.circular(14)),
          ),
          if (isSelected)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _themeTile(AppThemeMode mode, String title, {required SettingsTilePosition position}) {
    final bool selected = themeMode == mode;
    return SettingsNavTile(
      position: position,
      title: title,
      leadingIcon: selected ? Icons.check : null,
      onTap: () => setState(() => themeMode = mode),
      trailing: const SizedBox.shrink(),
    );
  }
} 