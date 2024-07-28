import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ChatConfigCard extends StatelessWidget {
  final List<Widget> children;
  final String title;
  final String strIcon;
  final Function(bool value)? onExpansionChanged;
  final CrossAxisAlignment? expandedCrossAxisAlignment;
  final double titleFontSize;
  final double iconSize;

  const ChatConfigCard({
    super.key,
    required this.title,
    required this.strIcon,
    required this.children,
    this.onExpansionChanged,
    this.expandedCrossAxisAlignment,
    this.titleFontSize = 18,
    this.iconSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.all(0),
      color: Colors.transparent,
      elevation: 0,
      child: ExpansionTile(
        expandedAlignment: Alignment.topLeft,
        expandedCrossAxisAlignment: expandedCrossAxisAlignment,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8.0),
        childrenPadding: const EdgeInsets.all(0.0),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.string(
              strIcon,
              height: iconSize,
              width: iconSize,
            ),
            const Padding(padding: EdgeInsets.all(4.0)),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: titleFontSize, fontWeight: FontWeight.w700),
              ),
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
