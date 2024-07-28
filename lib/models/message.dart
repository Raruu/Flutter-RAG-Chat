enum MessageRole { user, model, modelTyping }

class Message {
  late final Map<String, dynamic> textData;
  final MessageRole role;
  String get message => textData['generated_text'] ?? '';
  set message(String value) {
    textData['generated_text'] = value;
  }

  final int token;

  Message({
    Map<String, dynamic>? textData,
    String? message,
    required this.token,
    required this.role,
  }) {
    this.textData = textData ?? {};
    if (message != null) {
      this.textData['generated_text'] = message;
    }
  }
}
