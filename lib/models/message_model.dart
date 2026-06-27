class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type; // 'text'|'dedication'|'support'
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> j) => MessageModel(
        id: j['id'] as String,
        senderId: j['senderId'] as String,
        receiverId: j['receiverId'] as String,
        senderName: j['senderName'] as String,
        senderAvatar: j['senderAvatar'] as String?,
        content: j['content'] as String,
        type: j['type'] as String? ?? 'text',
        isRead: j['isRead'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'receiverId': receiverId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
        'content': content,
        'type': type,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
      };
}

class ConversationModel {
  final String userId;
  final String userName;
  final String? userAvatar;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ConversationModel({
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> j) =>
      ConversationModel(
        userId: j['userId'] as String,
        userName: j['userName'] as String,
        userAvatar: j['userAvatar'] as String?,
        lastMessage: j['lastMessage'] as String,
        lastMessageAt: DateTime.parse(j['lastMessageAt'] as String),
        unreadCount: j['unreadCount'] as int? ?? 0,
      );
}
