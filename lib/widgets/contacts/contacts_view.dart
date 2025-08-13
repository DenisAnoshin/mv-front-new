import 'package:flutter/material.dart';
import 'contacts_list.dart';

class ContactsView extends StatefulWidget {
  const ContactsView({
    super.key,
    required this.contacts,
    required this.onContactTap,
    this.topActions,
    this.showRightIndex = true,
    this.searchHint = 'Имя, фамилия или ник',
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
  });

  final List<ContactItem> contacts;
  final ValueChanged<ContactItem> onContactTap;
  final List<Widget>? topActions;
  final bool showRightIndex;
  final String searchHint;
  final EdgeInsetsGeometry padding;

  @override
  State<ContactsView> createState() => _ContactsViewState();
}

class _ContactsViewState extends State<ContactsView> {
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.topActions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
              filled: true,
              fillColor: const Color(0xFFF1F3F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        if (actions != null && actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: actions),
          ),
        if (actions != null && actions.isNotEmpty) const SizedBox(height: 8),
        Expanded(
          child: ContactsList(
            contacts: widget.contacts,
            query: _query,
            onTap: widget.onContactTap,
            padding: widget.padding,
            showRightIndex: widget.showRightIndex,
          ),
        ),
      ],
    );
  }
} 