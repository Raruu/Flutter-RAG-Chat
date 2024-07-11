enum MessageRole { user, model }

class Message {
  final MessageRole role;
  final String message;
  final int token;

  Message({
    required this.message,
    required this.token,
    required this.role,
  });
}