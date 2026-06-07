class ChatMessage {
  final String id;
  final int senderId;
  final int receiverId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });
}