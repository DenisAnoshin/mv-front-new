import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../stores/chat_store.dart';
import '../stores/user_store.dart';

/// Abstraction to fetch chats and messages. Later can be backed by real HTTP/WebSocket.
abstract class ChatRepository {
  Future<List<UserProfile>> fetchUsers();
  Future<List<ChatItem>> fetchChats({required String meUserId});

  /// Loads messages for chat. `limit` and `cursor` allow pagination when backend appears.
  /// For mocks, implementations may ignore them.
  Future<List<ChatMessage>> fetchMessages({
    required String chatId,
    required String meUserId,
    int? limit,
    String? cursor,
  });

  /// Loads a single bundle with chat info, related users and latest messages for initial open.
  Future<ChatBundle> fetchChatBundle({
    required String chatId,
    required String meUserId,
  });
}

class ChatBundle {
  final List<UserProfile> users;
  final List<ChatMessage> messages;
  final Map<String, dynamic> settings; // muted, pinned, custom notif, etc.

  const ChatBundle({required this.users, required this.messages, this.settings = const {}});
}

class MockJsonChatRepository implements ChatRepository {
  static const String _allPath = 'assets/mock/all_chats.json';

  bool _loaded = false;
  List<UserProfile> _usersCache = <UserProfile>[];
  List<ChatItem> _chatsCache = <ChatItem>[];
  final Map<String, List<Map<String, dynamic>>> _rawMessagesByChatId = <String, List<Map<String, dynamic>>>{};

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString(_allPath);
    final Map<String, dynamic> jsonMap = json.decode(raw) as Map<String, dynamic>;

    // Users
    _usersCache = ((jsonMap['users'] as List<dynamic>? ?? const <dynamic>[])).map((e) {
      final m = e as Map<String, dynamic>;
      return UserProfile(
        id: m['id'] as String,
        phone: m['phone'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
        username: m['username'] as String?,
        registeredAt: m['registeredAt'] != null ? DateTime.tryParse(m['registeredAt'] as String) : null,
        bio: m['bio'] as String?,
        isPremium: m['isPremium'] as bool?,
      );
    }).toList();

    // Chats + messages
    _chatsCache.clear();
    _rawMessagesByChatId.clear();
    final List<dynamic> chats = (jsonMap['chats'] as List<dynamic>? ?? const <dynamic>[]);
    for (final dynamic e in chats) {
      final m = e as Map<String, dynamic>;
      final chatId = m['id'] as String;
      _chatsCache.add(ChatItem(
        id: chatId,
        title: m['title'] as String,
        lastMessage: m['lastMessage'] as String? ?? '',
        lastTime: DateTime.parse(m['lastTime'] as String),
        unreadCount: (m['unreadCount'] as num?)?.toInt() ?? 0,
        type: _chatTypeFromString(m['type'] as String?),
        participantIds: (m['participantIds'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
        peerUserId: m['peerUserId'] as String?,
        memberCount: (m['memberCount'] as num?)?.toInt(),
        subscriberCount: (m['subscriberCount'] as num?)?.toInt(),
      ));

      final List<dynamic> msgs = (m['messages'] as List<dynamic>? ?? const <dynamic>[]);
      // Keep only the latest 30 if more provided
      final List<Map<String, dynamic>> asMaps = msgs.map((e) => (e as Map<String, dynamic>)).toList();
      final List<Map<String, dynamic>> last30 = asMaps.length > 30 ? asMaps.sublist(asMaps.length - 30) : asMaps;
      _rawMessagesByChatId[chatId] = last30;
    }

    _loaded = true;
  }

  @override
  Future<List<UserProfile>> fetchUsers() async {
    await _ensureLoaded();
    return _usersCache;
  }

  @override
  Future<List<ChatItem>> fetchChats({required String meUserId}) async {
    await _ensureLoaded();
    return _chatsCache;
  }

  @override
  Future<List<ChatMessage>> fetchMessages({
    required String chatId,
    required String meUserId,
    int? limit,
    String? cursor,
  }) async {
    await _ensureLoaded();
    final List<Map<String, dynamic>> raw = _rawMessagesByChatId[chatId] ?? const <Map<String, dynamic>>[];
    final List<ChatMessage> parsed = raw.map((e) => _messageFromMap(chatId: chatId, meUserId: meUserId, map: e)).toList();
    if (limit != null && parsed.length > limit) {
      return parsed.sublist(parsed.length - limit);
    }
    return parsed;
  }

  @override
  Future<ChatBundle> fetchChatBundle({required String chatId, required String meUserId}) async {
    await _ensureLoaded();
    final List<ChatMessage> messages = await fetchMessages(chatId: chatId, meUserId: meUserId);
    // Select users involved in this chat for enrichment
    final Set<String> userIds = <String>{};
    for (final m in messages) {
      userIds.add(m.senderId);
      userIds.addAll(m.reactions.values.expand((set) => set));
    }
    // Include peer/participants if present
    final ChatItem? chat = _chatsCache.cast<ChatItem?>().firstWhere((c) => c!.id == chatId, orElse: () => null);
    if (chat != null) {
      if (chat.peerUserId != null) userIds.add(chat.peerUserId!);
      userIds.addAll(chat.participantIds);
    }
    final List<UserProfile> users = _usersCache.where((u) => userIds.contains(u.id)).toList();
    return ChatBundle(users: users, messages: messages, settings: const {});
  }

  ChatType _chatTypeFromString(String? s) {
    switch (s) {
      case 'group':
        return ChatType.group;
      case 'channel':
        return ChatType.channel;
      case 'direct':
      default:
        return ChatType.direct;
    }
  }

  ChatMessage _messageFromMap({required String chatId, required String meUserId, required Map<String, dynamic> map}) {
    final String rawSenderId = map['senderId'] as String;
    // Allow simple placeholders in mocks to denote "current user"
    final bool isPlaceholderMe = rawSenderId == 'u_0000000000' || rawSenderId == r'$me' || rawSenderId.toLowerCase() == 'me';
    final String senderId = isPlaceholderMe ? meUserId : rawSenderId;
    final String text = map['text'] as String? ?? '';
    final String id = map['id'] as String? ?? 'm_${chatId}_${DateTime.now().microsecondsSinceEpoch}';
    final DateTime time = DateTime.parse(map['time'] as String);
    final String? statusStr = map['status'] as String?; // sending|sent|read|null
    final MessageStatus? status = _statusFromString(statusStr);

    // reactions: {"👍": ["u_1","u_2"]}
    final Map<String, dynamic> rxMap = (map['reactions'] as Map<String, dynamic>? ?? const {});
    final Map<String, Set<String>> reactions = rxMap.map((k, v) => MapEntry(k, (v as List<dynamic>).cast<String>().toSet()));

    // myReactions: ["👍","❤️"]
    final Set<String> myReactions = ((map['myReactions'] as List<dynamic>? ?? const <dynamic>[])).cast<String>().toSet();

    final bool isMine = senderId == meUserId;

    // Determine kind and optional attachments
    MessageKind kind = MessageKind.text;
    AudioAttachment? audio;
    final String? typeStr = map['type'] as String?; // e.g., 'text' | 'audio'
    if (typeStr == 'audio' || (map['audio'] is Map)) {
      kind = MessageKind.audio;
      final Map<String, dynamic> a = (map['audio'] as Map<String, dynamic>? ?? const {});
      final int durationSec = (a['durationSec'] as num?)?.toInt() ?? 0;
      final int sizeBytes = (a['sizeBytes'] as num?)?.toInt() ?? 0;
      final String? url = a['url'] as String?;
      final List<int> waveform = (a['waveform'] as List<dynamic>? ?? const []).map((e) => (e as num).toInt()).toList();
      audio = AudioAttachment(url: url, durationSec: durationSec, sizeBytes: sizeBytes, waveform: waveform);
    }

    return ChatMessage(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      time: time,
      isMine: isMine,
      status: isMine ? status : null,
      reactions: reactions,
      myReactions: myReactions,
      kind: kind,
      audio: audio,
    );
  }

  MessageStatus? _statusFromString(String? s) {
    switch (s) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'read':
        return MessageStatus.read;
      default:
        return null;
    }
  }
} 