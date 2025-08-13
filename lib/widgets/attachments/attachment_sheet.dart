import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/telegram_colors.dart';
import 'map_picker.dart';
import '../contacts/contacts_list.dart';

class AttachmentSheet extends StatefulWidget {
  const AttachmentSheet({super.key});

  @override
  State<AttachmentSheet> createState() => _AttachmentSheetState();
}

class _AttachmentSheetState extends State<AttachmentSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final double maxHeight = media.size.height * 0.78;
    final double initialHeight = min(media.size.height * 0.58, 540);

    final CurvedAnimation fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final CurvedAnimation slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    final CurvedAnimation jelly = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);

    return Stack(
      children: [
        FadeTransition(
          opacity: fade,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(slide),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(jelly),
              child: _SheetBody(maxHeight: maxHeight, initialHeight: initialHeight),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetBody extends StatefulWidget {
  final double maxHeight;
  final double initialHeight;
  const _SheetBody({required this.maxHeight, required this.initialHeight});

  @override
  State<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends State<_SheetBody> {
  double? _height;

  @override
  void initState() {
    super.initState();
    _height = widget.initialHeight;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() {
      _height = (_height! - d.delta.dy).clamp(360.0, widget.maxHeight);
    });
  }

  void _onDragEnd(DragEndDetails d) {
    final target = d.primaryVelocity != null && d.primaryVelocity! > 600 ? 360.0 : widget.initialHeight;
    setState(() => _height = target.clamp(360.0, widget.maxHeight));
  }

  @override
  Widget build(BuildContext context) {
    final radius = const BorderRadius.vertical(top: Radius.circular(18));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: _height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: _onDragUpdate,
              onVerticalDragEnd: _onDragEnd,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Недавние',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: TelegramColors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.more_horiz, color: Colors.grey, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _MockGalleryGrid(),
            ),
            const Divider(height: 1),
            // Bottom action row with strict height and clipping to prevent yellow overflow stripes
            Material(
              color: Colors.white,
              child: ClipRect(
                                  child: SizedBox(
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: const [
                          Expanded(child: _ActionTile(icon: Icons.photo, label: 'Галерея')),
                          Expanded(child: _ActionTile(icon: Icons.place, label: 'Место')),
                          Expanded(child: _ActionTile(icon: Icons.person, label: 'Контакт')),
                          Expanded(child: _ActionTile(icon: Icons.insert_drive_file, label: 'Файл')),
                        ],
                      ),
                    ),
                  ),
              ),
            ),
            const SizedBox(height: 4),
            SafeArea(top: false, child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}

class _MockGalleryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFB2EBF2),
      const Color(0xFFFFCDD2),
      const Color(0xFFC8E6C9),
      const Color(0xFFFFF9C4),
      const Color(0xFFD1C4E9),
      const Color(0xFFFFE0B2),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: 36,
      itemBuilder: (context, index) {
        final color = colors[index % colors.length];
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: color),
              Center(
                child: Icon(Icons.photo, color: Colors.black.withOpacity(0.35), size: 34),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.circle_outlined, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon; 
  final String label;
  const _ActionTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (label == 'Место') {
                Navigator.of(context).push(_MapPickerRoute());
              } else if (label == 'Контакт') {
                Navigator.of(context).push(_ContactsPickerRoute());
              }
            },
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(child: Icon(icon, color: Colors.grey.shade700, size: 18)),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: TelegramColors.textSecondary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MapPickerRoute extends PageRouteBuilder<void> {
  _MapPickerRoute()
      : super(
          opaque: false,
          pageBuilder: (_, __, ___) => const _MapPickerPage(),
          transitionsBuilder: (ctx, anim, __, child) {
            final slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(anim);
            return SlideTransition(position: slide, child: child);
          },
        );
}

class _MapPickerPage extends StatefulWidget {
  const _MapPickerPage();
  @override
  State<_MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<_MapPickerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text('Место', style: TextStyle(color: Colors.black)),
      ),
      body: MapPicker(
        onSend: (pos) {
          Navigator.pop(context); // close picker
          Navigator.pop(context); // close sheet
          // Here you can add sending logic or callback
        },
      ),
    );
  }
}

// Map body split to isolate platform-specific map widgets
class _MapPickerBody extends StatefulWidget {
  const _MapPickerBody();
  @override
  State<_MapPickerBody> createState() => _MapPickerBodyState();
}

class _MapPickerBodyState extends State<_MapPickerBody> {
  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
} 

class _ContactsPickerRoute extends PageRouteBuilder<void> {
  _ContactsPickerRoute()
      : super(
          opaque: false,
          pageBuilder: (_, __, ___) => const _ContactsPickerPage(),
          transitionsBuilder: (ctx, anim, __, child) {
            final slide = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic))
                .animate(anim);
            return SlideTransition(position: slide, child: child);
          },
        );
}

class _ContactsPickerPage extends StatefulWidget {
  const _ContactsPickerPage();
  @override
  State<_ContactsPickerPage> createState() => _ContactsPickerPageState();
}

class _ContactsPickerPageState extends State<_ContactsPickerPage> {
  final TextEditingController _search = TextEditingController();
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final all = mockContacts();
    final selectedItems = all.where((c) => _selected.contains(c.id)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        title: const Text('Выберите контакты', style: TextStyle(color: Colors.black)),
      ),
      body: Column(
        children: [
          // Selected chips row
          if (selectedItems.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final c = selectedItems[i];
                  return InputChip(
                    label: Text(c.fullName),
                    onDeleted: () => setState(() => _selected.remove(c.id)),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: selectedItems.length,
              ),
            ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Найти по имени',
                filled: true,
                fillColor: Color(0xFFF2F2F7),
                border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: ContactsList(
              contacts: all,
              query: _search.text,
              onTap: (c) {
                setState(() {
                  if (_selected.contains(c.id)) {
                    _selected.remove(c.id);
                  } else {
                    _selected.add(c.id);
                  }
                });
              },
              showRightIndex: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _selected.isEmpty ? null : () {
              Navigator.pop(context); // close picker
              Navigator.pop(context); // close sheet
            },
            child: Text('Отправить  ${_selected.length}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
} 