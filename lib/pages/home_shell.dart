import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';
import '../theme/telegram_colors.dart';
import '../stores/chat_store.dart';
import 'chat_list_page.dart';
import 'settings/settings_page.dart';
import 'contacts_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 1; // default to Chats

  @override
  Widget build(BuildContext context) {
    final pages = const [ContactsPage(), ChatListPage(), SettingsPage()];
    final unreadChats = context.select<ChatStore, int>((s) => s.chats.fold<int>(0, (sum, c) => sum + (c.unreadCount)));

    final Color bg = const Color(0xFFFAFAFA); // slightly darker than pure white
    final Color inactive = const Color(0xFF8E8E93);
    final Color active = TelegramColors.primary;

    Widget morphIconWithBadge({
      required IconData icon,
      required IconData selectedIcon,
      required bool selected,
      required int count,
    }) {
      Widget base = _MorphingIcon(
        icon: icon,
        selectedIcon: selectedIcon,
        selected: selected,
      );

      if (count <= 0) return base;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          base,
          Positioned(
            right: -8,
            top: -4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: Container(
                key: ValueKey<int>(count),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? active : Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count > 999 ? '999+' : '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: bg,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE5E5EA), // subtle grey top border like Telegram/iOS
              width: 1,
            ),
          ),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: bg,
            indicatorColor: Colors.transparent, // remove selection pill/outline
            elevation: 0,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(color: selected ? active : inactive);
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                color: selected ? active : inactive,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              );
            }),
            surfaceTintColor: Colors.transparent,
            height: 64,
          ),
                    child: NavigationBar(
             labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
             animationDuration: const Duration(milliseconds: 450),
             selectedIndex: _index,
             onDestinationSelected: (i) => setState(() => _index = i),
             destinations: [
              NavigationDestination(
                icon: morphIconWithBadge(
                  icon: FeatherIcons.users,
                  selectedIcon: FeatherIcons.userCheck,
                  selected: _index == 0,
                  count: 0,
                ),
                label: 'Contacts',
              ),
              NavigationDestination(
                icon: morphIconWithBadge(
                  icon: FeatherIcons.messageCircle,
                  selectedIcon: FeatherIcons.messageSquare,
                  selected: _index == 1,
                  count: unreadChats,
                ),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: morphIconWithBadge(
                  icon: FeatherIcons.settings,
                  selectedIcon: FeatherIcons.settings,
                  selected: _index == 2,
                  count: 0,
                ),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MorphingIcon extends StatelessWidget {
  const _MorphingIcon({
    required this.icon,
    required this.selectedIcon,
    required this.selected,
  });

  final IconData icon;
  final IconData selectedIcon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Duration duration = const Duration(milliseconds: 420);
    final Curve curve = Curves.easeInOutCubic;
    final Color? targetColor = IconTheme.of(context).color;

    return TweenAnimationBuilder<Color?>(
      duration: duration,
      curve: curve,
      tween: ColorTween(end: targetColor),
      builder: (context, color, child) {
        return AnimatedSwitcher(
          duration: duration,
          switchInCurve: curve,
          switchOutCurve: curve,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Icon(
            selected ? selectedIcon : icon,
            key: ValueKey<bool>(selected),
            color: color,
          ),
        );
      },
    );
  }
} 