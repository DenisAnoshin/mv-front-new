import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/chat_store.dart';
import '../stores/user_store.dart';
import '../theme/telegram_colors.dart';
import 'telegram_login_page.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'chat_detail_page.dart';
import 'new_chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  Future<void>? _loadFuture;
  int _tabIndex = 0; // 0 = All, 1 = Unread
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFuture ??= _load(context);
  }

  Route _slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween<Offset>(begin: begin, end: end).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
    );
  }

  Future<void> _load(BuildContext context) async {
    final userStore = context.read<UserStore>();
    final chatStore = context.read<ChatStore>();
    final user = userStore.currentUser;
    if (user != null) {
      await chatStore.loadMockChats(user, userStore: userStore);
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      if (diff.inDays == 1) return 'вчера';
      if (diff.inDays < 7) return '${diff.inDays} дн';
      return '${dateTime.day}.${dateTime.month.toString().padLeft(2, '0')}';
    }

    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAvatar(String title) {
    final letters = title
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();
    final colors = [
      const Color(0xFFE17076),
      const Color(0xFF7BC862),
      const Color(0xFF65AADD),
      const Color(0xFFF2B44D),
      const Color(0xFFAE7DAC),
      const Color(0xFF6EC9CB),
      const Color(0xFF8DA6DF),
    ];
    final color = colors[title.hashCode % colors.length];

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letters,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, {required int unreadCount}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + actions
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8, right: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Чаты', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
              Row(children: [
                _circleBtn(Icons.more_horiz),
                const SizedBox(width: 8),
                _circleBtn(Icons.add, onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewChatPage()),
                  );
                }),
              ]),
            ],
          ),
        ),
        // Search
        TextField(
          controller: _search,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Люди, чаты и сообщения',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF8E8E93)),
            filled: true,
            fillColor: const Color(0xFFF1F3F6),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),
        // Tabs (static)
        Row(children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _tabIndex = 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Все',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: _tabIndex == 0 ? FontWeight.w600 : FontWeight.w500,
                      color: TelegramColors.textPrimary,
                    )),
                const SizedBox(height: 4),
                SizedBox(
                  width: 32,
                  child: Divider(
                    thickness: 2,
                    color: _tabIndex == 0 ? TelegramColors.primary : Colors.transparent,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _tabIndex = 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Новые',
                      style: TextStyle(
                        fontSize: 16,
                        color: _tabIndex == 1 ? TelegramColors.textPrimary : TelegramColors.textSecondary,
                        fontWeight: _tabIndex == 1 ? FontWeight.w600 : FontWeight.w500,
                      )),
                  const SizedBox(width: 6),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EDF5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$unreadCount', style: const TextStyle(fontSize: 12, color: TelegramColors.textPrimary)),
                    ),
                ]),
                const SizedBox(height: 4),
                SizedBox(
                  width: 48,
                  child: Divider(
                    thickness: 2,
                    color: _tabIndex == 1 ? TelegramColors.primary : Colors.transparent,
                    height: 2,
                  ),
                ),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Purple banner
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6C4DFF), Color(0xFF8A66FF)]),
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Включите уведомления', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Чтобы не пропустить важное', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.notifications_active, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _circleBtn(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: TelegramColors.textPrimary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserStore>().currentUser;
    final unreadCount = context.select<ChatStore, int>((s) => s.chats.where((c) => c.unreadCount > 0).length);
    return Scaffold(
      backgroundColor: TelegramColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _header(context, unreadCount: unreadCount),
            ),
            Expanded(
              child: FutureBuilder<void>(
                future: _loadFuture,
                builder: (context, snapshot) {
                  return RefreshIndicator(
                    color: TelegramColors.primary,
                    onRefresh: () => _load(context),
                    child: Consumer<ChatStore>(
                      builder: (context, chatStore, _) {
                        List<ChatItem> chats = chatStore.chats;
                        if (_tabIndex == 1) {
                          chats = chats.where((c) => c.unreadCount > 0).toList();
                        }
                        if (_query.isNotEmpty) {
                          chats = chats
                              .where((c) => c.title.toLowerCase().contains(_query) || c.lastMessage.toLowerCase().contains(_query))
                              .toList();
                        }
                        if (snapshot.connectionState == ConnectionState.waiting && chats.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(TelegramColors.primary),
                            ),
                          );
                        }
                        if (chats.isEmpty) {
                          return const Center(
                            child: Text(
                              'Нет чатов',
                              style: TextStyle(
                                color: TelegramColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: chats.length,
                          separatorBuilder: (context, index) => Container(
                            height: 0.5,
                            margin: const EdgeInsets.only(left: 88),
                            color: TelegramColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final chat = chats[index];
                            final isChannel = chat.type == ChatType.channel;

                            return Material(
                              color: TelegramColors.background,
                              child: InkWell(
                                splashColor: TelegramColors.ripple,
                                highlightColor: TelegramColors.ripple,
                                onTap: () {
                                  Navigator.of(context).push(_slideFromRight(
                                    ChatDetailPage(chat: chat),
                                  ));
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          _buildAvatar(chat.title),
                                          if (chat.type == ChatType.direct)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 18,
                                                height: 18,
                                                decoration: BoxDecoration(
                                                  color: TelegramColors.onlineIndicator,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: TelegramColors.background,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                if (isChannel)
                                                  const Padding(
                                                    padding: EdgeInsets.only(right: 4),
                                                    child: Icon(
                                                      Icons.campaign,
                                                      size: 16,
                                                      color: TelegramColors.textSecondary,
                                                    ),
                                                  ),
                                                Expanded(
                                                  child: Text(
                                                    chat.title,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w500,
                                                      color: TelegramColors.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    chat.lastMessage,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: TelegramColors.textSecondary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (chat.unreadCount > 0) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    constraints: const BoxConstraints(
                                                      minWidth: 20,
                                                      minHeight: 20,
                                                    ),
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: TelegramColors.unreadBadge,
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                                                      style: const TextStyle(
                                                        color: TelegramColors.textOnPrimary,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatTime(chat.lastTime),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: chat.unreadCount > 0
                                              ? TelegramColors.primary
                                              : TelegramColors.textSecondary,
                                          fontWeight: chat.unreadCount > 0
                                              ? FontWeight.w500
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 