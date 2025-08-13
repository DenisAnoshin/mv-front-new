import 'package:flutter/material.dart';
import '../../../widgets/settings/settings_card.dart';
import '../../../widgets/settings/settings_tiles.dart';

class OtherNotificationsPage extends StatefulWidget {
  const OtherNotificationsPage({super.key});

  @override
  State<OtherNotificationsPage> createState() => _OtherNotificationsPageState();
}

class _OtherNotificationsPageState extends State<OtherNotificationsPage> {
  bool notifyContactsRegistration = true;
  bool inAppPushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Прочие уведомления', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            SettingsCard(children: [
              SettingsSwitchTile(
                title: 'Уведомлять о регистрации\nпользователей из ваших контактов',
                value: notifyContactsRegistration,
                onChanged: (v) => setState(() => notifyContactsRegistration = v),
              ),
            ]),
            const SizedBox(height: 16),
            SettingsCard(children: [
              SettingsSwitchTile(
                title: 'Push-уведомления в приложении',
                subtitle: 'Покажем сообщение в верхней части\nэкрана, похожее на системное\nуведомление',
                value: inAppPushNotifications,
                onChanged: (v) => setState(() => inAppPushNotifications = v),
              ),
            ]),
          ],
        ),
      ),
    );
  }
} 