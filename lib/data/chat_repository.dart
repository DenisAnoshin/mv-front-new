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
  static const String _basePath = 'assets/mock';

  @override
  Future<List<UserProfile>> fetchUsers() async {
    final raw = await rootBundle.loadString('$_basePath/users.json');
    final Map<String, dynamic> jsonMap = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> users = (jsonMap['users'] as List<dynamic>? ?? const []);
    return users.map((e) {
      final m = e as Map<String, dynamic>;
      return UserProfile(
        id: m['id'] as String,
        phone: m['phone'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
      );
    }).toList();
  }

  @override
  Future<List<ChatItem>> fetchChats({required String meUserId}) async {
    final raw = await rootBundle.loadString('$_basePath/chats.json');
    final Map<String, dynamic> jsonMap = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> chats = (jsonMap['chats'] as List<dynamic>? ?? const []);

    List<ChatItem> items = chats.map((e) {
      final m = e as Map<String, dynamic>;
      return ChatItem(
        id: m['id'] as String,
        title: m['title'] as String,
        lastMessage: m['lastMessage'] as String? ?? '',
        lastTime: DateTime.parse(m['lastTime'] as String),
        unreadCount: (m['unreadCount'] as num?)?.toInt() ?? 0,
        type: _chatTypeFromString(m['type'] as String?),
        participantIds: (m['participantIds'] as List<dynamic>? ?? const []).cast<String>(),
        peerUserId: m['peerUserId'] as String?,
        memberCount: (m['memberCount'] as num?)?.toInt(),
        subscriberCount: (m['subscriberCount'] as num?)?.toInt(),
      );
    }).toList();
    return items;
  }

  @override
  Future<List<ChatMessage>> fetchMessages({
    required String chatId,
    required String meUserId,
    int? limit,
    String? cursor,
  }) async {
    final raw = await rootBundle.loadString('$_basePath/messages_$chatId.json');
    final Map<String, dynamic> jsonMap = json.decode(raw) as Map<String, dynamic>;
    final List<dynamic> messages = (jsonMap['messages'] as List<dynamic>? ?? const []);
    return messages.map((e) => _messageFromMap(chatId: chatId, meUserId: meUserId, map: e as Map<String, dynamic>)).toList();
  }

  @override
  Future<ChatBundle> fetchChatBundle({required String chatId, required String meUserId}) async {
    final raw = await rootBundle.loadString('$_basePath/bundles/chat_$chatId.json');
    final Map<String, dynamic> jsonMap = json.decode(raw) as Map<String, dynamic>;

    final users = ((jsonMap['users'] as List<dynamic>? ?? const [])).map((e) {
      final m = e as Map<String, dynamic>;
      return UserProfile(
        id: m['id'] as String,
        phone: m['phone'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
      );
    }).toList();

    final List<ChatMessage> messages = ((jsonMap['messages'] as List<dynamic>? ?? const [])).map((e) {
      return _messageFromMap(chatId: chatId, meUserId: meUserId, map: e as Map<String, dynamic>);
    }).toList();

    final Map<String, dynamic> settings = (jsonMap['settings'] as Map<String, dynamic>?) ?? const {};
    return ChatBundle(users: users, messages: messages, settings: settings);
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