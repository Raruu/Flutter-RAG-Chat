import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ChatConfigCard extends StatelessWidget {
  final List<Widget> children;
  final String title;
  final String strIcon;
  final Function(bool value)? onExpansionChanged;
  final CrossAxisAlignment? expandedCrossAxisAlignment;

  const ChatConfigCard({
    super.key,
    required this.title,
    required this.strIcon,
    required this.children,
    this.onExpansionChanged,
    this.expandedCrossAxisAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0),
      color: Colors.white,
      elevation: 0,
      child: ExpansionTile(
        expandedCrossAxisAlignment: expandedCrossAxisAlignment,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
        childrenPadding: const EdgeInsets.all(0.0),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.string(strIcon),
            const Padding(padding: EdgeInsets.all(4.0)),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        children: [
          const Padding(
            padding: EdgeInsets.all(5.0),
          ),
          ...children,
        ],
      ),
    );
  }
}
