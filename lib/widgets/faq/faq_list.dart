import 'package:flutter/material.dart';

class FaqItem {
  final String question;
  final String answer;
  const FaqItem({required this.question, required this.answer});
}

class FaqGroup {
  final String title;
  final IconData icon;
  final List<FaqItem> items;
  const FaqGroup({required this.title, required this.icon, required this.items});
}

class FaqList extends StatefulWidget {
  final List<FaqGroup> groups;
  const FaqList({super.key, required this.groups});

  @override
  State<FaqList> createState() => _FaqListState();
}

class _FaqListState extends State<FaqList> {
  int? openGroupIndex;

  @override
  Widget build(BuildContext context) {
    return ExpansionPanelList.radio(
      elevation: 0,
      expandedHeaderPadding: EdgeInsets.zero,
      materialGapSize: 12,
      children: [
        for (int i = 0; i < widget.groups.length; i++) _buildGroup(i, widget.groups[i]),
      ],
    );
  }

  ExpansionPanelRadio _buildGroup(int index, FaqGroup group) {
    return ExpansionPanelRadio(
      value: index,
      canTapOnHeader: true,
      headerBuilder: (context, isExpanded) {
        return _GroupHeader(group: group);
      },
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          children: [
            for (final item in group.items) _FaqTile(item: item),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final FaqGroup group;
  const _GroupHeader({required this.group});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(group.icon, color: Colors.black87),
          const SizedBox(width: 12),
          Expanded(
            child: Text(group.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final FaqItem item;
  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          title: Text(item.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.answer,
                style: const TextStyle(color: Color(0xFF444444), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 