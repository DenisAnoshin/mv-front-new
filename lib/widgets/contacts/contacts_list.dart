import 'package:flutter/material.dart';
import '../../widgets/avatar_circle.dart';

class ContactItem {
  final String id;
  final String fullName;
  final String? phone;
  final String? lastSeen; // e.g. "4 ч назад" или "был(-а) 8 авг.)"
  const ContactItem({required this.id, required this.fullName, this.phone, this.lastSeen});
}

List<ContactItem> mockContacts() => const [
      ContactItem(id: 'c_a1', fullName: 'Атланты', lastSeen: 'был(-а) 8 авг.'),
      ContactItem(id: 'c_a2', fullName: 'Алена Сайт', lastSeen: 'был(-а) 30 июля'),
      ContactItem(id: 'c_a3', fullName: 'Антон Церковь', lastSeen: 'был(-а) 27 июня'),
      ContactItem(id: 'c_b1', fullName: 'Владимир', lastSeen: '4 ч назад'),
      ContactItem(id: 'c_b2', fullName: 'Владимир Сайт', lastSeen: 'был(-а) 1 авг.'),
      ContactItem(id: 'c_b3', fullName: 'Владислав Солнечный Остров', lastSeen: 'был(-а) 27 июля'),
      ContactItem(id: 'c_e1', fullName: 'Евгений Web', lastSeen: 'был(-а) 21 июля'),
      ContactItem(id: 'c_e2', fullName: 'Евгений Биржа', lastSeen: 'был(-а) 2 авг.'),
      ContactItem(id: 'c_e3', fullName: 'Евгения Биржа'),
      ContactItem(id: 'c_g1', fullName: 'Глеб Мирный'),
      ContactItem(id: 'c_d1', fullName: 'Дмитрий Проектный', lastSeen: 'был(-а) 3 дня назад'),
      ContactItem(id: 'c_s1', fullName: 'Сергей Техподдержка', lastSeen: 'онлайн недавно'),
      ContactItem(id: 'c_k1', fullName: 'Кирилл Дизайн'),
      ContactItem(id: 'c_l1', fullName: 'Лена Маркетинг', lastSeen: 'был(-а) вчера'),
      ContactItem(id: 'c_m1', fullName: 'Мария Рекрутинг', lastSeen: 'был(-а) 12 июл.'),
    ];

class ContactsList extends StatefulWidget {
  final List<ContactItem> contacts;
  final String query; // external filter; pass '' if not used
  final void Function(ContactItem contact) onTap;
  final EdgeInsetsGeometry padding;
  final bool showRightIndex;

  const ContactsList({
    super.key,
    required this.contacts,
    required this.onTap,
    this.query = '',
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 24),
    this.showRightIndex = true,
  });

  @override
  State<ContactsList> createState() => _ContactsListState();
}

class _ContactsListState extends State<ContactsList> {
  final ScrollController _scroll = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};

  Map<String, List<ContactItem>> _grouped(List<ContactItem> list) {
    final map = <String, List<ContactItem>>{};
    for (final c in list) {
      final letter = c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : '#';
      map.putIfAbsent(letter, () => []);
      map[letter]!.add(c);
    }
    for (final e in map.entries) {
      e.value.sort((a, b) => a.fullName.compareTo(b.fullName));
    }
    return map;
  }

  List<ContactItem> _filtered() {
    final q = widget.query.trim().toLowerCase();
    if (q.isEmpty) return widget.contacts;
    return widget.contacts.where((c) => c.fullName.toLowerCase().contains(q)).toList();
  }

  void _jumpTo(String letter) {
    final key = _sectionKeys[letter];
    if (key == null) return;
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 200));
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered();
    final grouped = _grouped(data);
    final letters = grouped.keys.toList()..sort();

    return Stack(
      children: [
        ListView.builder(
          controller: _scroll,
          padding: widget.padding,
          itemCount: letters.fold<int>(0, (acc, k) => acc + 1 + grouped[k]!.length),
          itemBuilder: (context, index) {
            int cursor = 0;
            for (final letter in letters) {
              final key = _sectionKeys.putIfAbsent(letter, () => GlobalKey());
              if (index == cursor) return _header(letter, key: key);
              cursor++;
              final items = grouped[letter]!;
              if (index < cursor + items.length) {
                final c = items[index - cursor];
                return _tile(c);
              }
              cursor += items.length;
            }
            return const SizedBox.shrink();
          },
        ),
        if (widget.showRightIndex)
          Positioned(
            right: 4,
            top: 120,
            bottom: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: letters
                      .map((l) => GestureDetector(
                            onTap: () => _jumpTo(l),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                              child: Text(l, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12)),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _header(String letter, {required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(letter, style: const TextStyle(color: Color(0xFF8E8E93), fontWeight: FontWeight.w600)),
    );
  }

  Widget _tile(ContactItem c) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      leading: AvatarCircle(title: c.fullName, size: 44, gradient: AvatarCircle.gradientFor(c.fullName), letterColor: Colors.white),
      title: Text(c.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: c.lastSeen != null ? Text(c.lastSeen!, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13)) : null,
      onTap: () => widget.onTap(c),
    );
  }
} 