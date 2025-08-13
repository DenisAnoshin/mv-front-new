import 'package:flutter/material.dart';
import '../widgets/contacts/contacts_list.dart';
import '../widgets/contacts/contacts_view.dart';
import '../stores/chat_store.dart';
import 'chat_detail_page.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  Widget _action(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0A84FF)),
          const SizedBox(width: 14),
          Text(title, style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 17, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = mockContacts();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text('Начать общение', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ContactsView(
          contacts: contacts,
          searchHint: 'Найти по имени',
          topActions: [
            _action(Icons.groups_outlined, 'Создать групповой чат'),
            _action(Icons.link, 'Пригласить по ссылке'),
            _action(Icons.qr_code_2, 'Пригласить по QR-коду'),
            _action(Icons.phone_outlined, 'Найти по номеру'),
          ],
          onContactTap: (c) {
            final chat = ChatItem(
              id: 'd_${c.id}',
              title: c.fullName,
              lastMessage: '',
              lastTime: DateTime.now(),
              type: ChatType.direct,
              participantIds: const [],
              peerUserId: c.id,
            );
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ChatDetailPage(chat: chat)),
            );
          },
        ),
      ),
    );
  }
} 