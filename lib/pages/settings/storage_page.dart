import 'package:flutter/material.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class StoragePage extends StatelessWidget {
  const StoragePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Память', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SettingsCard(children: const [
            SettingsNavTile(
              position: SettingsTilePosition.single,
              title: 'Хранить медиа в кэше\nустройства',
              subtitle: 'После удаления медиа\nможно загрузить снова',
              trailingText: 'Месяц',
            ),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('данные'),
          SettingsCard(children: [
            const SettingsNavTile(position: SettingsTilePosition.first, title: 'Стикеры', trailingText: '77 МБ'),
            const SettingsNavTile(position: SettingsTilePosition.middle, title: 'Фото', trailingText: '97 КБ'),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _ClearCacheButton(sizeLabel: '77,1 МБ', onPressed: () {}),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ClearCacheButton extends StatelessWidget {
  final String sizeLabel;
  final VoidCallback onPressed;
  const _ClearCacheButton({required this.sizeLabel, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Очистить кэш'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Text(sizeLabel, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
} 