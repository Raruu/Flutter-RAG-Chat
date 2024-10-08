import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/my_colors.dart';

class NiceButton extends StatefulWidget {
  final double borderRadiusCircular;
  final Color backgroundColor;
  final Function() onTap;
  final Function(bool value)? onHover;
  final String? strIcon;
  final double iconSize;
  final String text;
  final Color textColor;
  final Color textHoverColor;
  final Color splashColor;
  final Color? hoverColor;
  final Duration hoverDuration;
  final Border? border;
  final EdgeInsets padding;

  const NiceButton({
    super.key,
    this.borderRadiusCircular = 20,
    this.backgroundColor = MyColors.bgTintBlue,
    required this.onTap,
    this.strIcon,
    this.iconSize = 32.0,
    required this.text,
    this.splashColor = MyColors.bgTintBlue,
    this.hoverColor = MyColors.bgTintPink,
    this.hoverDuration = const Duration(microseconds: 0),
    this.border,
    this.onHover,
    this.textColor = MyColors.textTintBlue,
    this.textHoverColor = Colors.black,
    this.padding = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
  });

  @override
  State<NiceButton> createState() => _NiceButtonState();
}

class _NiceButtonState extends State<NiceButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        // border: widget.border,
        borderRadius: BorderRadius.circular(widget.borderRadiusCircular),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: widget.splashColor,
          hoverColor: widget.hoverColor,
          hoverDuration: widget.hoverDuration,
          onHover: (value) {
            widget.onHover?.call(value);
            setState(() => isHover = value);
          },
          child: Ink(
            decoration: BoxDecoration(
              border: widget.border,
              borderRadius: BorderRadius.circular(widget.borderRadiusCircular),
            ),
            child: Padding(
              padding: widget.padding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                      child: Align(
                    alignment: Alignment.centerLeft,
                    child: widget.strIcon != null
                        ? SvgPicture.string(
                            widget.strIcon!,
                            height: widget.iconSize,
                            width: widget.iconSize,
                          )
                        : const SizedBox(),
                  )),
                  Expanded(
                    flex: 2,
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 32),
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Center(
                          child: Text(
                            widget.text,
                            style: TextStyle(
                                color: isHover
                                    ? widget.textHoverColor
                                    : widget.textColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
