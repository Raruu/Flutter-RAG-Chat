import 'package:flutter/material.dart';

import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final int? token;
  final Color backgroundColor;
  final MessageRole role;
  const ChatBubble({
    super.key,
    required this.text,
    this.backgroundColor = Colors.white70,
    this.token,
    this.role = MessageRole.user,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      textDirection:
          role == MessageRole.user ? TextDirection.rtl : TextDirection.ltr,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: backgroundColor,
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        if (token != null)
          Text(
            '$token Tokens~',
            style: const TextStyle(fontSize: 12),
          ),
      ],
    );
  }
}
