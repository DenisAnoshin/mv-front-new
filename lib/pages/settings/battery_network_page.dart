import 'package:flutter/material.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class BatteryNetworkPage extends StatefulWidget {
  const BatteryNetworkPage({super.key});

  @override
  State<BatteryNetworkPage> createState() => _BatteryNetworkPageState();
}

class _BatteryNetworkPageState extends State<BatteryNetworkPage> {
  bool gifsAutoplay = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Экономия батареи и сети', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const SettingsSectionLabel('фото'),
          SettingsCard(children: const [
            SettingsNavTile(position: SettingsTilePosition.single, title: 'Автозагрузка', trailingText: 'Всегда'),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('видео'),
          SettingsCard(children: const [
            SettingsNavTile(position: SettingsTilePosition.first, title: 'Качество при отправке', trailingText: '720p'),
            SettingsNavTile(position: SettingsTilePosition.last, title: 'Автовоспроизведение', trailingText: 'Всегда'),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('гифки'),
          SettingsCard(children: [
            SettingsSwitchTile(
              position: SettingsTilePosition.single,
              title: 'Автовоспроизведение',
              value: gifsAutoplay,
              onChanged: (v) => setState(() => gifsAutoplay = v),
            ),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('аудиосообщения'),
          SettingsCard(children: const [
            SettingsNavTile(position: SettingsTilePosition.single, title: 'Автозагрузка', trailingText: 'Всегда'),
          ]),
        ],
      ),
    );
  }
} 