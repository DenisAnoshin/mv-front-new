import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/telegram_colors.dart';
import '../widgets/avatar_circle.dart';

class UserProfilePage extends StatelessWidget {
  final String title;
  final String? phone;
  final String? username;
  final String? bio;
  final String? entityId; // userId / chatId / channelId for future use

  const UserProfilePage({
    super.key,
    required this.title,
    this.phone,
    this.username,
    this.bio,
    this.entityId,
  });

  String _formatPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '+7 000 000 00 00';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 11) return '+$digits';
    // +7 xxx xxx xx xx
    return '+${digits[0]} ${digits.substring(1, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9, 11)}';
  }

  String _usernameOrMock() {
    if (username != null && username!.isNotEmpty) return username!;
    final handle = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return '@$handle';
  }

  @override
  Widget build(BuildContext context) {
    final r = Random(title.hashCode);
    final tenDigits = List.generate(10, (_) => r.nextInt(10)).join();
    final mockPhone = _formatPhone(phone ?? '+7$tenDigits');

    return Scaffold(
      backgroundColor: TelegramColors.background,
      body: DefaultTabController(
        length: 6,
        child: NestedScrollView(
          headerSliverBuilder: (context, inner) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 300,
              backgroundColor: TelegramColors.appBarBackground,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: TelegramColors.appBarText),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Edit', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Header photo placeholder gradient
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFCCA97E), Color(0xFF6B553E)],
                        ),
                      ),
                    ),
                    // Foreground content
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'last seen recently',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _HeaderAction(icon: Icons.call, label: 'call', onTap: () {}),
                              _HeaderAction(icon: Icons.videocam, label: 'video', onTap: () {}),
                              _HeaderAction(icon: Icons.notifications_off, label: 'mute', onTap: () {}),
                              _HeaderAction(icon: Icons.search, label: 'search', onTap: () {}),
                              _HeaderAction(
                                icon: Icons.more_horiz,
                                label: 'more',
                                onTap: () => _showMore(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: _DetailsCard(
                  phone: mockPhone,
                  username: _usernameOrMock(),
                  dob: '9 Jul',
                  bio: bio ?? 'Motion Graphic Designer',
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsHeaderDelegate(
                const TabBar(
                  isScrollable: true,
                  indicatorColor: TelegramColors.primary,
                  labelColor: TelegramColors.primary,
                  unselectedLabelColor: TelegramColors.textSecondary,
                  tabs: [
                    Tab(text: 'Media'),
                    Tab(text: 'Saved'),
                    Tab(text: 'Files'),
                    Tab(text: 'Music'),
                    Tab(text: 'Voice'),
                    Tab(text: 'Links'),
                  ],
                ),
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              _EmptyTab(label: 'Media'),
              _EmptyTab(label: 'Saved'),
              _EmptyTab(label: 'Files'),
              _EmptyTab(label: 'Music'),
              _EmptyTab(label: 'Voice'),
              _EmptyTab(label: 'Links'),
            ],
          ),
        ),
      ),
      floatingActionButton: AvatarCircle(title: title, size: 64, showOnline: true, onTap: () {}),
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _MoreItem(icon: Icons.wallpaper, label: 'Change Wallpaper'),
            _MoreItem(icon: Icons.lock_outline, label: 'Start Secret Chat'),
            _MoreItem(icon: Icons.share_outlined, label: 'Share Contact'),
            _MoreItem(icon: Icons.card_giftcard, label: 'Send a Gift'),
            Divider(height: 1),
            _MoreItem(icon: Icons.timer_outlined, label: 'Enable Auto-Delete'),
            _MoreItem(icon: Icons.delete_sweep_outlined, label: 'Clear Messages'),
            Divider(height: 1),
            _MoreItem(icon: Icons.block, label: 'Block User', danger: true),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Ink(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String phone;
  final String username;
  final String dob;
  final String bio;

  const _DetailsCard({
    required this.phone,
    required this.username,
    required this.dob,
    required this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF6F5F8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          _tile('mobile', phone, onTap: () {}),
          const Divider(height: 1, color: TelegramColors.divider),
          _tile('username', username, valueColor: Colors.deepPurple, onTap: () {}),
          const Divider(height: 1, color: TelegramColors.divider),
          _tile('date of birth', dob),
          const Divider(height: 1, color: TelegramColors.divider),
          _tile('bio', bio),
        ],
      ),
    );
  }

  Widget _tile(String title, String value, {Color? valueColor, VoidCallback? onTap}) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: TelegramColors.textSecondary)),
      subtitle: Text(
        value,
        style: TextStyle(color: valueColor ?? TelegramColors.textPrimary, fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}

class _TabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabsHeaderDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabsHeaderDelegate oldDelegate) => false;
}

class _EmptyTab extends StatelessWidget {
  final String label;
  const _EmptyTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label tab is empty (mock)',
        style: const TextStyle(color: TelegramColors.textSecondary),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool danger;

  const _MoreItem({required this.icon, required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : TelegramColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontSize: 16)),
      onTap: () => Navigator.of(context).pop(),
    );
  }
} 