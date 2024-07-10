import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/my_colors.dart';

class NiceButton extends StatefulWidget {
  final double borderRadiusCircular;
  final Color backgroundColor;
  final Function() onTap;
  final String? strIcon;
  final double iconSize;
  final String text;
  final Color splashColor;
  final Color? hoverColor;

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
  });

  @override
  State<NiceButton> createState() => _NiceButtonState();
}

class _NiceButtonState extends State<NiceButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadiusCircular),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          splashColor: widget.splashColor,
          hoverColor: widget.hoverColor,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
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
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 32),
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: Center(
                        child: Text(
                          widget.text,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 20),
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
    );
  }
}
