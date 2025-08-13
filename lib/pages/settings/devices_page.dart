import 'package:flutter/material.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final List<_Session> activeSessions = const [
    _Session(
      icon: Icons.desktop_windows_outlined,
      color: Color(0xFFFFA000),
      title: 'E1504FA',
      subtitle: 'Telegram Desktop 6.0.2',
      meta: 'Amsterdam, The Netherlands · 1 hour ago',
    ),
    _Session(
      icon: Icons.language,
      color: Color(0xFF20C997),
      title: 'Chrome 138',
      subtitle: 'Telegram Widgets',
      meta: 'Amsterdam, The Netherlands · 08.08.25',
    ),
    _Session(
      icon: Icons.language,
      color: Color(0xFF20C997),
      title: 'Chrome 133',
      subtitle: 'Telegram Web 2.2 K',
      meta: 'Amsterdam, The Netherlands · 19.07.25',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Устройства', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Изм.', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _headerIllustration(),
          const SizedBox(height: 12),
          _linkDesktopButton(),
          const SizedBox(height: 20),
          const SettingsSectionLabel('это устройство'),
          _thisDeviceCard(),
          const SizedBox(height: 20),
          const SettingsSectionLabel('активные сессии'),
          _activeSessionsList(),
        ],
      ),
    );
  }

  Widget _headerIllustration() {
    return Column(
      children: const [
        Icon(Icons.laptop_mac, size: 84, color: Color(0xFF8E8E93)),
        SizedBox(height: 8),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Link ', style: TextStyle(color: Color(0xFF8E8E93))),
            TextSpan(text: 'Telegram Desktop', style: TextStyle(color: Color(0xFF0A84FF))),
            TextSpan(text: ' or ', style: TextStyle(color: Color(0xFF8E8E93))),
            TextSpan(text: 'Telegram Web', style: TextStyle(color: Color(0xFF0A84FF))),
            TextSpan(text: ' by\nscanning a QR code.', style: TextStyle(color: Color(0xFF8E8E93))),
          ]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _linkDesktopButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF007AFF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () {},
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text('Link Desktop Device', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _thisDeviceCard() {
    return SettingsCard(children: const [
      ListTile(
        title: Text('iPhone 13', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        subtitle: Text('Telegram iOS 11.13.2\nKrasnodar, Russia · online'),
        isThreeLine: true,
      ),
      _TerminateOthersTile(),
    ]);
  }

  Widget _activeSessionsList() {
    return SettingsCard(children: [
      for (int i = 0; i < activeSessions.length; i++)
        _sessionTile(activeSessions[i], position: i == 0
            ? (activeSessions.length == 1 ? SettingsTilePosition.single : SettingsTilePosition.first)
            : (i == activeSessions.length - 1 ? SettingsTilePosition.last : SettingsTilePosition.middle)),
    ]);
  }

  BorderRadius _borderFor(SettingsTilePosition position) {
    const double r = 18;
    switch (position) {
      case SettingsTilePosition.single:
        return BorderRadius.circular(r);
      case SettingsTilePosition.first:
        return const BorderRadius.only(topLeft: Radius.circular(r), topRight: Radius.circular(r));
      case SettingsTilePosition.middle:
        return BorderRadius.zero;
      case SettingsTilePosition.last:
        return const BorderRadius.only(bottomLeft: Radius.circular(r), bottomRight: Radius.circular(r));
    }
  }

  Widget _sessionTile(_Session s, {required SettingsTilePosition position}) {
    final radius = _borderFor(position);
    return InkWell(
      borderRadius: radius,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
          return const Color(0x14000000);
        }
        return null;
      }),
      child: ListTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: s.color.withOpacity(0.15),
          child: Icon(s.icon, color: s.color),
        ),
        title: Text(s.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        subtitle: Text('${s.subtitle}\n${s.meta}'),
        isThreeLine: true,
        onTap: () {},
      ),
    );
  }
}

class _PhoneIcon extends StatelessWidget {
  const _PhoneIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: const Color(0xFF007AFF), borderRadius: BorderRadius.circular(8)),
      child: const Icon(Icons.phone_iphone, color: Colors.white),
    );
  }
}

class _TerminateOthersTile extends StatelessWidget {
  const _TerminateOthersTile();
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Завершить все другие сессии', style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w600)),
      onTap: () {},
    );
  }
}

class _Session {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String meta;
  const _Session({required this.icon, required this.color, required this.title, required this.subtitle, required this.meta});
} 