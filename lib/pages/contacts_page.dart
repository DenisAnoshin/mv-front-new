import 'package:flutter/material.dart';
import '../widgets/contacts/contacts_list.dart';
import '../widgets/contacts/contacts_view.dart';
import '../stores/chat_store.dart';
import 'chat_detail_page.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  @override
  Widget build(BuildContext context) {
    final contacts = mockContacts();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0, right: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Контакты', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                    InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.add, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ContactsView(
                  contacts: contacts,
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
            ],
          ),
        ),
      ),
    );
  }
} 