import 'package:flutter/material.dart';
import 'other_notifications_page.dart';
import '../../../widgets/settings/settings_card.dart';
import '../../../widgets/settings/settings_tiles.dart';
import '../../../widgets/settings/settings_action_sheet.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

enum GroupNotificationsSetting { showAll, repliesOnly, hide }

class _NotificationsPageState extends State<NotificationsPage> {
  bool enableAllNotifications = false;
  bool showSenderAndText = true;
  GroupNotificationsSetting groupSetting = GroupNotificationsSetting.showAll;

  String get _groupSettingTitle {
    switch (groupSetting) {
      case GroupNotificationsSetting.showAll:
        return 'Показывать все';
      case GroupNotificationsSetting.repliesOnly:
        return 'Только ответы';
      case GroupNotificationsSetting.hide:
        return 'Не показывать';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Уведомления', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _enableBanner(context),
            const SizedBox(height: 12),
            SettingsCard(children: [
              SettingsSwitchTile(
                position: SettingsTilePosition.single,
                title: 'Включить все уведомления',
                value: enableAllNotifications,
                onChanged: (v) => setState(() => enableAllNotifications = v),
              ),
            ]),
            const SizedBox(height: 20),
            const SettingsSectionLabel('новые сообщения'),
            SettingsCard(children: [
              SettingsSwitchTile(
                position: SettingsTilePosition.single,
                title: 'Показывать в уведомлениях\nотправителя и текст',
                value: showSenderAndText,
                onChanged: (v) => setState(() => showSenderAndText = v),
              ),
            ]),
            const SizedBox(height: 20),
            const SettingsSectionLabel('групповые чаты'),
            SettingsCard(children: [
              SettingsNavTile(
                position: SettingsTilePosition.single,
                title: 'Уведомления',
                trailingText: _groupSettingTitle,
                onTap: _openGroupSettingSheet,
              ),
            ]),
            const SizedBox(height: 20),
            const SettingsSectionLabel('прочие уведомления'),
            SettingsCard(children: [
              SettingsNavTile(
                position: SettingsTilePosition.single,
                title: 'Прочие уведомления',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OtherNotificationsPage()),
                ),
              ),
            ]),
            const SizedBox(height: 28),
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Сбросить настройки уведомлений',
                  style: TextStyle(color: Color(0xFFFF3B30), fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGroupSettingSheet() async {
    final result = await showSettingsOptionsSheet<GroupNotificationsSetting>(
      context: context,
      title: 'Уведомления',
      selected: groupSetting,
      options: const [
        SettingsOption(value: GroupNotificationsSetting.showAll, label: 'Показывать все'),
        SettingsOption(value: GroupNotificationsSetting.repliesOnly, label: 'Только ответы'),
        SettingsOption(value: GroupNotificationsSetting.hide, label: 'Не показывать', destructive: true),
      ],
    );
    if (result != null) setState(() => groupSetting = result);
  }

  Widget _enableBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E44FF), Color(0xFF8F57FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Включите уведомления', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Чтобы не пропустить важное', style: TextStyle(color: Color(0xFFE6E6EA), fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30),
          ),
        ],
      ),
    );
  }
} 