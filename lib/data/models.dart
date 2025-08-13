class UserDto {
  final String id;
  final String phone;
  final String displayName;
  final String? avatarUrl;
  const UserDto({required this.id, required this.phone, required this.displayName, this.avatarUrl});

  factory UserDto.fromMap(Map<String, dynamic> m) => UserDto(
        id: m['id'] as String,
        phone: m['phone'] as String? ?? '',
        displayName: m['displayName'] as String? ?? '',
        avatarUrl: m['avatarUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'phone': phone,
        'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
}

class ChatDto {
  final String id;
  final String type; // direct|group|channel
  final String title;
  final String? peerUserId; // for directs
  final List<String> participantIds; // groups: subset for preview
  final int? memberCount;
  final int? subscriberCount;
  final String lastMessage;
  final DateTime lastTime;
  final int unreadCount;

  const ChatDto({
    required this.id,
    required this.type,
    required this.title,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    this.peerUserId,
    this.participantIds = const <String>[],
    this.memberCount,
    this.subscriberCount,
  });

  factory ChatDto.fromMap(Map<String, dynamic> m) => ChatDto(
        id: m['id'] as String,
        type: m['type'] as String? ?? 'direct',
        title: m['title'] as String? ?? '',
        lastMessage: m['lastMessage'] as String? ?? '',
        lastTime: DateTime.parse(m['lastTime'] as String),
        unreadCount: (m['unreadCount'] as num?)?.toInt() ?? 0,
        peerUserId: m['peerUserId'] as String?,
        participantIds: (m['participantIds'] as List<dynamic>? ?? const []).cast<String>(),
        memberCount: (m['memberCount'] as num?)?.toInt(),
        subscriberCount: (m['subscriberCount'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'title': title,
        'lastMessage': lastMessage,
        'lastTime': lastTime.toIso8601String(),
        'unreadCount': unreadCount,
        if (peerUserId != null) 'peerUserId': peerUserId,
        if (participantIds.isNotEmpty) 'participantIds': participantIds,
        if (memberCount != null) 'memberCount': memberCount,
        if (subscriberCount != null) 'subscriberCount': subscriberCount,
      };
}

class MessageDto {
  final String id;
  final String chatId;
  final String senderId; // for channels: can be channel id
  final String text;
  final DateTime time;
  final String? status; // sending|sent|read for outgoing only
  final Map<String, List<String>> reactions; // emoji -> userIds
  final List<String> myReactions;

  const MessageDto({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.time,
    this.status,
    this.reactions = const <String, List<String>>{},
    this.myReactions = const <String>[],
  });

  factory MessageDto.fromMap(Map<String, dynamic> m) => MessageDto(
        id: m['id'] as String,
        chatId: m['chatId'] as String,
        senderId: m['senderId'] as String,
        text: m['text'] as String? ?? '',
        time: DateTime.parse(m['time'] as String),
        status: m['status'] as String?,
        reactions: (m['reactions'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, (v as List<dynamic>).cast<String>()),
        ),
        myReactions: (m['myReactions'] as List<dynamic>? ?? const []).cast<String>(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'chatId': chatId,
        'senderId': senderId,
        'text': text,
        'time': time.toIso8601String(),
        if (status != null) 'status': status,
        if (reactions.isNotEmpty) 'reactions': reactions,
        if (myReactions.isNotEmpty) 'myReactions': myReactions,
      };
} 