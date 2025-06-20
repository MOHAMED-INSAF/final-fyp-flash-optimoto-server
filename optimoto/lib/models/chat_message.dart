enum MessageType { user, bot, system }

class ChatMessage {
  final String id;
  final String message;
  final MessageType type;
  final DateTime timestamp;
  final bool isTyping;

  const ChatMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isTyping = false,
  });

  factory ChatMessage.user(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.bot(String message) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: message,
      type: MessageType.bot,
      timestamp: DateTime.now(),
    );
  }

  factory ChatMessage.typing() {
    return ChatMessage(
      id: 'typing',
      message: '',
      type: MessageType.bot,
      timestamp: DateTime.now(),
      isTyping: true,
    );
  }

  String get timeString {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
