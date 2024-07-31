import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/utils/my_colors.dart';

import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final int? token;
  final Color backgroundColor;
  final MessageRole role;
  final Function()? showContext;
  final Function()? deleteFunc;
  final Function()? regenerate;
  final Function()? userEditFunc;

  const ChatBubble({
    super.key,
    required this.text,
    this.backgroundColor = Colors.white70,
    this.token,
    this.role = MessageRole.user,
    this.showContext,
    this.deleteFunc,
    this.regenerate,
    this.userEditFunc,
  });

  @override
  Widget build(BuildContext context) {
    bool isHover = false;
    Function(Function()) setState = (p0) {};
    return MouseRegion(
      onEnter: (event) => setState(() => isHover = true),
      onExit: (event) => setState(() => isHover = false),
      child: Wrap(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Visibility(
                  visible: role == MessageRole.model,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: MyColors.bgSelectedBlue.withOpacity(0.5),
                    ),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: showContext,
                          child: const Text(
                            'Show Context',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          tooltip: 'Regenerate',
                          onPressed: regenerate,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          tooltip: 'Delete',
                          onPressed: deleteFunc,
                        )
                      ],
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(vertical: 2.0)),
                SelectableText(
                  text,
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          if (role == MessageRole.user)
            StatefulBuilder(
              builder: (context, thisState) {
                setState = thisState;
                double width = 80;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.decelerate,
                  width: isHover ? width : 0,
                  child: SizedBox(
                    width: width,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Delete',
                            onPressed: deleteFunc,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                            onPressed: userEditFunc,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          if (token != null)
            Text(
              '$token Tokens~',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
