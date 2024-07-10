import "package:flutter/material.dart";

class VerticalText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final double spacing;
  const VerticalText({
    super.key,
    required this.text,
    this.textStyle,
    this.spacing = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      direction: Axis.vertical,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: text
          .split("")
          .map((string) => Text(string, style: textStyle))
          .toList(),
    );
  }
}
