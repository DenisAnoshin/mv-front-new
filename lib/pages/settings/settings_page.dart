import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/avatar_circle.dart';
import '../../stores/user_store.dart';
import 'notifications/notifications_page.dart';
import 'devices_page.dart';
import 'privacy_page.dart';
import 'folders_page.dart';
import 'battery_network_page.dart';
import 'storage_page.dart';
import 'appearance_page.dart';
import 'help_page.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<UserStore>().currentUser;
    final title = me?.displayName ?? 'Me';
    final phone = me?.phone ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_2, color: Color(0xFF8E8E93)),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Column(
                children: [
                  AvatarCircle(
                    title: title,
                    size: 96,
                    gradient: AvatarCircle.gradientFor(title),
                    letterColor: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SettingsCard(children: [
              SettingsNavTile(
                position: SettingsTilePosition.first,
                title: 'Уведомления',
                leadingIcon: Icons.notifications_outlined,
                trailing: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.circle, color: Colors.red, size: 10),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                ]),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
              ),
              SettingsNavTile(
                position: SettingsTilePosition.middle,
                title: 'Устройства',
                leadingIcon: Icons.devices_other_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DevicesPage()),
                ),
              ),
              SettingsNavTile(
                position: SettingsTilePosition.middle,
                title: 'Приватность',
                leadingIcon: Icons.lock_outline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPage()),
                ),
              ),
              const SettingsNavTile(position: SettingsTilePosition.middle, title: 'Сообщения', leadingIcon: Icons.chat_bubble_outline),
              const SettingsNavTile(position: SettingsTilePosition.middle, title: 'Избранное', leadingIcon: Icons.bookmark_border),
              SettingsNavTile(
                position: SettingsTilePosition.last,
                title: 'Папки',
                leadingIcon: Icons.folder_open,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FoldersPage()),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SettingsCard(children: [
              SettingsNavTile(
                position: SettingsTilePosition.first,
                title: 'Экономия батареи и сети',
                leadingIcon: Icons.savings_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BatteryNetworkPage()),
                ),
              ),
              SettingsNavTile(
                position: SettingsTilePosition.last,
                title: 'Память',
                leadingIcon: Icons.sd_storage_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StoragePage()),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            SettingsCard(children: [
              SettingsNavTile(
                position: SettingsTilePosition.first,
                title: 'Оформление',
                leadingIcon: Icons.color_lens_outlined,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AppearancePage()),
                ),
              ),
              SettingsNavTile(
                position: SettingsTilePosition.last,
                title: 'Помощь',
                leadingIcon: Icons.help_outline,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpPage()),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
} 