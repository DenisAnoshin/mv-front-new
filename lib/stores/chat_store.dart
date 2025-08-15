import 'package:flutter/foundation.dart';
import 'user_store.dart';
import '../data/chat_repository.dart';

enum MessageStatus { sending, sent, read }

enum ChatType { direct, group, channel }

/// Kind/type of a message (text, audio, images, etc.)
enum MessageKind { text, audio }

/// Metadata for an audio message
class AudioAttachment {
  final String? url; // local asset or network url (mocked)
  final int durationSec; // total duration in seconds
  final int sizeBytes; // file size in bytes
  final List<int> waveform; // simplified waveform (0..15 per bar)

  const AudioAttachment({this.url, required this.durationSec, required this.sizeBytes, this.waveform = const <int>[]});
}


class ChatItem {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;
  final ChatType type;
  // For group/channel chats: list of participant userIds (subset for mocks)
  final List<String> participantIds;
  // For direct chats: the peer user id
  final String? peerUserId;
  // For group chats: member count (can be larger than participantIds.length)
  final int? memberCount;
  // For channels: subscriber count
  final int? subscriberCount;

  const ChatItem({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.type = ChatType.direct,
    this.participantIds = const <String>[],
    this.peerUserId,
    this.memberCount,
    this.subscriberCount,
  });

  ChatItem copyWith({
    String? lastMessage,
    DateTime? lastTime,
    int? unreadCount,
    List<String>? participantIds,
    String? peerUserId,
    int? memberCount,
    int? subscriberCount,
  }) {
    return ChatItem(
      id: id,
      title: title,
      lastMessage: lastMessage ?? this.lastMessage,
      lastTime: lastTime ?? this.lastTime,
      unreadCount: unreadCount ?? this.unreadCount,
      type: type,
      participantIds: participantIds ?? this.participantIds,
      peerUserId: peerUserId ?? this.peerUserId,
      memberCount: memberCount ?? this.memberCount,
      subscriberCount: subscriberCount ?? this.subscriberCount,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime time;
  final bool isMine;
  final MessageStatus? status; // только для исходящих
  // Reactions: emoji -> set of userIds
  final Map<String, Set<String>> reactions;
  // Emojis that current user reacted with
  final Set<String> myReactions;
  // Message kind and optional metadata
  final MessageKind kind;
  final AudioAttachment? audio;
  

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.time,
    required this.isMine,
    this.status,
    this.reactions = const <String, Set<String>>{},
    this.myReactions = const <String>{},
    this.kind = MessageKind.text,
    this.audio,
  });

  ChatMessage copyWith({
    MessageStatus? status,
    Map<String, Set<String>>? reactions,
    Set<String>? myReactions,
    MessageKind? kind,
    AudioAttachment? audio,
    
  }) => ChatMessage(
        id: id,
        chatId: chatId,
        senderId: senderId,
        text: text,
        time: time,
        isMine: isMine,
        status: status ?? this.status,
        reactions: reactions ?? this.reactions,
        myReactions: myReactions ?? this.myReactions,
        kind: kind ?? this.kind,
        audio: audio ?? this.audio,
        
      );
}

class ChatStore extends ChangeNotifier {
  ChatStore({ChatRepository? repository}) : _repository = repository ?? MockJsonChatRepository();

  final ChatRepository _repository;
  final List<ChatItem> _chats = <ChatItem>[];
  final Map<String, List<ChatMessage>> _chatIdToMessages = <String, List<ChatMessage>>{};

  List<ChatItem> get chats => List.unmodifiable(_chats);
  List<ChatMessage> messagesFor(String chatId) => List.unmodifiable(_chatIdToMessages[chatId] ?? const []);

  /// One-shot bundle fetch: messages + users + settings for a chat
  Future<void> loadChatBundle(String chatId, UserProfile me, {required UserStore userStore}) async {
    try {
      final bundle = await _repository.fetchChatBundle(chatId: chatId, meUserId: me.id);
      if (bundle.users.isNotEmpty) {
        userStore.upsertUsers(bundle.users);
      }
      _chatIdToMessages[chatId] = bundle.messages;
      // Optional: apply settings like mute/pin when we introduce per-chat settings store
      markAllAsRead(chatId);
    } catch (_) {
      // Fallback to existing message loader
      await loadMockMessages(chatId, me, userStore: userStore);
    }
  }

  Future<void> loadMockChats(UserProfile user, {UserStore? userStore}) async {
    try {
      // Load users first to enrich names/avatars in UI
      final users = await _repository.fetchUsers();
      userStore?.upsertUsers(users);

      final chats = await _repository.fetchChats(meUserId: user.id);
      _chats
        ..clear()
        ..addAll(chats);
      notifyListeners();
    } catch (_) {
      // Fallback to previous in-memory seed if JSON assets are not present
      await Future.delayed(const Duration(milliseconds: 50));

      final users = <UserProfile>[
        const UserProfile(id: 'u_maria', phone: '+79000000001', displayName: 'Мария'),
        const UserProfile(id: 'u_ivan', phone: '+79000000002', displayName: 'Иван'),
        const UserProfile(id: 'u_olga', phone: '+79000000003', displayName: 'Ольга'),
        const UserProfile(id: 'u_pavel', phone: '+79000000004', displayName: 'Павел'),
        const UserProfile(id: 'u_anna', phone: '+79000000005', displayName: 'Анна'),
        const UserProfile(id: 'u_oleg', phone: '+79000000006', displayName: 'Олег'),
        const UserProfile(id: 'u_kate', phone: '+79000000007', displayName: 'Катя'),
        const UserProfile(id: 'u_denis', phone: '+79000000008', displayName: 'Денис'),
        const UserProfile(id: 'u_sergey', phone: '+79000000009', displayName: 'Сергей'),
        const UserProfile(id: 'u_vika', phone: '+79000000010', displayName: 'Вика'),
      ];
      userStore?.upsertUsers(users);

      final frontendIds = ['u_anna', 'u_oleg', 'u_kate', 'u_pavel', 'u_sergey', 'u_vika'];
      final travelIds = ['u_maria', 'u_ivan', 'u_olga', 'u_pavel', 'u_anna', 'u_denis', 'u_sergey'];

      _chats
        ..clear()
        ..addAll([
          ChatItem(
            id: 'd_maria',
            title: 'Мария',
            lastMessage: 'Завтра созвон 11:00? Перекину ссылку',
            lastTime: DateTime.now().subtract(const Duration(minutes: 7)),
            unreadCount: 1,
            type: ChatType.direct,
            participantIds: const [],
            peerUserId: 'u_maria',
          ),
          ChatItem(
            id: 'd_ivan',
            title: 'Иван',
            lastMessage: 'Ок, договорились ��',
            lastTime: DateTime.now().subtract(const Duration(minutes: 18)),
            unreadCount: 0,
            type: ChatType.direct,
            participantIds: const [],
            peerUserId: 'u_ivan',
          ),
          ChatItem(
            id: 'grp_frontend',
            title: 'Frontend Crew',
            lastMessage: 'Давайте переведём проект на Flutter 3.24',
            lastTime: DateTime.now().subtract(const Duration(minutes: 3)),
            unreadCount: 3,
            type: ChatType.group,
            participantIds: frontendIds,
            memberCount: 42,
          ),
          ChatItem(
            id: 'grp_travel',
            title: 'Поход на выходных',
            lastMessage: 'Маршрут через озеро, вид шикарный!',
            lastTime: DateTime.now().subtract(const Duration(minutes: 25)),
            unreadCount: 2,
            type: ChatType.group,
            participantIds: travelIds,
            memberCount: 18,
          ),
          ChatItem(
            id: 'ch_tech',
            title: 'Tech Digest',
            lastMessage: 'Релиз Dart 3.5: ускорения и Records everywhere',
            lastTime: DateTime.now().subtract(const Duration(minutes: 12)),
            unreadCount: 0,
            type: ChatType.channel,
            participantIds: const [],
            subscriberCount: 52100,
          ),
        ]);

      notifyListeners();
    }
  }

  Future<void> loadMockMessages(String chatId, UserProfile me, {UserStore? userStore}) async {
    try {
      final items = await _repository.fetchMessages(chatId: chatId, meUserId: me.id);
      _chatIdToMessages[chatId] = items;
      markAllAsRead(chatId);
    } catch (_) {
      // Keep previous in-memory generation when JSON not present
      await Future.delayed(const Duration(milliseconds: 60));
      final now = DateTime.now();
      final chat = _chats.firstWhere((c) => c.id == chatId, orElse: () => _chats.first);

      int autoId = 0;
      ChatMessage m({required String sender, required String text, int minutesAgo = 0, bool mine = false, MessageStatus? status, Map<String, Set<String>>? rx, Set<String>? myRx}) {
        autoId++;
        return ChatMessage(
          id: 'm_${chatId}_$autoId',
          chatId: chatId,
          senderId: sender,
          text: text,
          time: now.subtract(Duration(minutes: minutesAgo)),
          isMine: mine,
          status: status,
          reactions: rx ?? const {},
          myReactions: myRx ?? const {},
          kind: MessageKind.text,
        );
      }

      List<ChatMessage> messages = <ChatMessage>[];

      // No generic autogen: keep empty when assets are missing
      _chatIdToMessages[chatId] = const <ChatMessage>[];
      markAllAsRead(chatId);
    }
  }

  void markAllAsRead(String chatId) {
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx == -1) return;
    final chat = _chats[idx];
    _chats[idx] = chat.copyWith(unreadCount: 0);
    notifyListeners();
  }

  Future<void> sendMessage({required String chatId, required String text, required UserProfile me}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final chat = _chats.firstWhere((c) => c.id == chatId);
    if (chat.type == ChatType.channel) {
      // Non-admin cannot send messages to channel in mocks
      return;
    }

    final sending = ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: me.id,
      text: trimmed,
      time: DateTime.now(),
      isMine: true,
      status: MessageStatus.sending,
      reactions: const {},
      myReactions: const {},
    );

    final list = _chatIdToMessages.putIfAbsent(chatId, () => <ChatMessage>[]);
    list.add(sending);

    // Обновляем карточку чата
    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      _chats[idx] = _chats[idx].copyWith(lastMessage: trimmed, lastTime: sending.time);
    }
    notifyListeners();

    // Эмуляция перехода статусов: sending -> sent
    await Future.delayed(const Duration(milliseconds: 250));
    final lastIndex = list.lastIndexWhere((m) => m.id == sending.id);
    if (lastIndex != -1) {
      list[lastIndex] = list[lastIndex].copyWith(status: MessageStatus.sent);
      notifyListeners();
    }

    // Мокаем входящий ответ и помечаем исходящее как прочитанное
    await Future.delayed(const Duration(milliseconds: 500));
    final reply = ChatMessage(
      id: 'm_reply_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: chat.peerUserId ?? 'peer_$chatId',
      text: 'Ответ на: "$trimmed"',
      time: DateTime.now(),
      isMine: false,
      status: null,
      reactions: const {},
      myReactions: const {},
    );
    list.add(reply);

    // Помечаем последнее моё как read
    final myIdx = list.lastIndexWhere((m) => m.isMine);
    if (myIdx != -1) {
      list[myIdx] = list[myIdx].copyWith(status: MessageStatus.read);
    }

    // Увеличим счётчик непрочитанных
    if (idx != -1) {
      final current = _chats[idx];
      _chats[idx] = current.copyWith(
        lastMessage: reply.text,
        lastTime: reply.time,
        unreadCount: current.unreadCount + 1,
      );
    }

    notifyListeners();
  }

  /// Creates and appends an audio message (mock) so it appears in the chat immediately
  Future<void> sendAudioMessage({
    required String chatId,
    required int durationSec,
    required UserProfile me,
    String? url,
    int? sizeBytes,
    List<int> waveform = const <int>[],
  }) async {
    final chat = _chats.firstWhere((c) => c.id == chatId);
    if (chat.type == ChatType.channel) return;

    final int estimatedSize = sizeBytes ?? (durationSec * 8 * 1024); // ~64 kbps

    final sending = ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: me.id,
      text: '',
      time: DateTime.now(),
      isMine: true,
      status: MessageStatus.sending,
      reactions: const {},
      myReactions: const {},
      kind: MessageKind.audio,
      audio: AudioAttachment(url: url, durationSec: durationSec, sizeBytes: estimatedSize, waveform: waveform),
    );

    final list = _chatIdToMessages.putIfAbsent(chatId, () => <ChatMessage>[]);
    list.add(sending);

    final idx = _chats.indexWhere((c) => c.id == chatId);
    if (idx != -1) {
      _chats[idx] = _chats[idx].copyWith(lastMessage: 'Voice message • ${durationSec}s', lastTime: sending.time);
    }
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 250));
    final lastIndex = list.lastIndexWhere((m) => m.id == sending.id);
    if (lastIndex != -1) {
      list[lastIndex] = list[lastIndex].copyWith(status: MessageStatus.sent);
      notifyListeners();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    final reply = ChatMessage(
      id: 'm_reply_${DateTime.now().microsecondsSinceEpoch}',
      chatId: chatId,
      senderId: chat.peerUserId ?? 'peer_${chatId}',
      text: 'Голосовое ок! 👌',
      time: DateTime.now(),
      isMine: false,
      status: null,
      reactions: const {},
      myReactions: const {},
      kind: MessageKind.text,
    );
    list.add(reply);

    final myIdx = list.lastIndexWhere((m) => m.isMine);
    if (myIdx != -1) {
      list[myIdx] = list[myIdx].copyWith(status: MessageStatus.read);
    }

    if (idx != -1) {
      final current = _chats[idx];
      _chats[idx] = current.copyWith(lastMessage: reply.text, lastTime: reply.time, unreadCount: current.unreadCount + 1);
    }

    notifyListeners();
  }

  void toggleReaction({
    required String chatId,
    required String messageId,
    required String emoji,
    required String myUserId,
  }) {
    final list = _chatIdToMessages[chatId];
    if (list == null) return;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;
    final m = list[idx];
    final newCounts = <String, Set<String>>{}..addAll(m.reactions.map((k, v) => MapEntry(k, Set<String>.from(v))));
    final newMy = Set<String>.from(m.myReactions);

    final currentSet = newCounts.putIfAbsent(emoji, () => <String>{});
    if (currentSet.contains(myUserId)) {
      currentSet.remove(myUserId);
      if (currentSet.isEmpty) newCounts.remove(emoji);
      newMy.remove(emoji);
    } else {
      currentSet.add(myUserId);
      newMy.add(emoji);
    }

    list[idx] = m.copyWith(reactions: newCounts, myReactions: newMy);
    notifyListeners();
  }

  void deleteMessage({required String chatId, required String messageId}) {
    final list = _chatIdToMessages[chatId];
    if (list == null) return;
    list.removeWhere((m) => m.id == messageId);
    // slight delay helps AnimatedList capture removal properly when called from context menu
    Future.microtask(() => notifyListeners());
  }

  void clear() {
    _chats.clear();
    _chatIdToMessages.clear();
    notifyListeners();
  }
} 