import 'dart:convert';

import '../controllers/chat_database.dart';
import 'message_context.dart';

enum MessageRole { user, model, modelTyping }

class Message {
  String message;
  int? token;
  final MessageRole role;
  MessageContext? messageContext;

  Message({
    this.message = '',
    this.token = 0,
    required this.role,
    this.messageContext,
  });

  Message.fromMap(Map<String, dynamic> map)
      : message = map[ChatDatabase.message] as String,
        token = map[ChatDatabase.messageToken] as int?,
        role = MessageRole.values[map[ChatDatabase.role] as int],
        messageContext = map[ChatDatabase.messageContext] != 'null'
            ? MessageContext.fromMap(
                jsonDecode(map[ChatDatabase.messageContext]))
            : null;

  Map<String, Object> toMap() => {
        ChatDatabase.message: message,
        ChatDatabase.role: role.index,
        ChatDatabase.messageContext: jsonEncode(messageContext?.toMap()),
        ChatDatabase.messageToken: token!,
      };
}
