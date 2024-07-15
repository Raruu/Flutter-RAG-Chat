import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../utils/my_colors.dart';

class ChatBubbleTyping extends StatefulWidget {
  const ChatBubbleTyping({super.key});

  @override
  State<ChatBubbleTyping> createState() => _ChatBubbleTypingState();
}

class _ChatBubbleTypingState extends State<ChatBubbleTyping>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double animationCalculate(double x) {
    x = x + (_controller.value % 1);
    return 7 * math.sin(x * 2 * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Container(
          width: 100,
          height: 50,
          decoration: BoxDecoration(
            color: MyColors.bgTintBlue.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20.0),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...List.generate(
                3,
                (index) {
                  double dy = [0.0, 0.2, 0.7][index];
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, animationCalculate(dy)),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: MyColors.textTintBlue,
                        ),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ],
    );
  }
}
