import 'package:flutter/material.dart';
import '../../widgets/settings/settings_card.dart';
import '../../widgets/settings/settings_tiles.dart';

class FoldersPage extends StatelessWidget {
  const FoldersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF1F3F6),
        foregroundColor: Colors.black,
        centerTitle: true,
        title: const Text('Папки', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Изменить', style: TextStyle(color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          SettingsCard(children: [
            SettingsNavTile(
              title: 'Все',
              leadingIcon: Icons.chat_bubble_outline,
              trailing: const SizedBox.shrink(),
              onTap: () {},
            ),
            SettingsNavTile(
              title: 'Новые',
              leadingIcon: Icons.chat_bubble,
              onTap: () {},
            ),
            _createFolderTile(context),
          ]),
          const SizedBox(height: 20),
          const SettingsSectionLabel('рекомендованные папки'),
          _recommendedTile(context, title: 'Личные', onTap: () {}),
        ],
      ),
    );
  }

  Widget _createFolderTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add, color: Color(0xFF0A84FF)),
      title: const Text('Создать папку', style: TextStyle(color: Color(0xFF0A84FF), fontSize: 17, fontWeight: FontWeight.w600)),
      onTap: () {},
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _recommendedTile(BuildContext context, {required String title, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const Spacer(),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 