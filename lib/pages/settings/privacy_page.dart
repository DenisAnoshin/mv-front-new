import 'package:flutter/material.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  bool secureMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Приватность', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SettingsCard(children: [
            SettingsLeadingSwitchRow(
              position: SettingsTilePosition.first,
              leadingIcon: Icons.lock_outline,
              title: 'Безопасный режим',
              subtitle: 'ПИН-код на настройки',
              value: secureMode,
              onChanged: (v) => setState(() => secureMode = v),
            ),
            SettingsNavTile(position: SettingsTilePosition.middle, title: 'Поиск по номеру телефона', trailingText: 'Все', onTap: () {}),
            SettingsNavTile(position: SettingsTilePosition.middle, title: 'Звонки', trailingText: 'Все', onTap: () {}),
            SettingsNavTile(position: SettingsTilePosition.last, title: 'Приглашения', trailingText: 'Все', onTap: () {}),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('информация'),
          SettingsCard(children: [
            SettingsNavTile(position: SettingsTilePosition.first, title: 'Статус «в сети»', trailingText: 'Контакты', onTap: () {}),
            SettingsNavTile(
              position: SettingsTilePosition.last,
              title: 'Чёрный список',
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('сессии'),
          _currentSessionCard(),
        ],
      ),
    );
  }

  Widget _currentSessionCard() {
    return SettingsCard(children: [
      ListTile(
        title: const Text('Max iOS (текущая)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        subtitle: const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('iPhone 13, iOS 16.6.1 Krasnodar, IP\n95.25.181.88'),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.circle, color: Color(0xFF34C759), size: 12),
            SizedBox(width: 6),
            Text('в сети', style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.w600)),
          ],
        ),
        isThreeLine: true,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        child: GestureDetector(
          onTap: () {},
          child: const Text(
            'Завершить все сессии, кроме текущей',
            style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w600),
          ),
        ),
      )
    ]);
  }
} 