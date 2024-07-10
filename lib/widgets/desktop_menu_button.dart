import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';
import '../utils/my_colors.dart';

class DesktopMenuButton extends StatefulWidget {
  final String stringSvg;
  final String? stringSvgSelected;
  final double iconSize;
  final double paddingIconText;
  final String text;
  final bool textVisibilty;
  final bool isSelected;
  final Function() onTap;

  const DesktopMenuButton({
    super.key,
    required this.stringSvg,
    required this.text,
    this.iconSize = 32,
    this.paddingIconText = 16.0,
    required this.onTap,
    required this.textVisibilty,
    this.isSelected = false,
    this.stringSvgSelected,
  });

  @override
  State<DesktopMenuButton> createState() => _DesktopMenuButtonState();
}

class _DesktopMenuButtonState extends State<DesktopMenuButton> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(64.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHover: (value) {
            setState(() {
              isHover = value;
            });
          },
          splashColor: Colors.transparent,
          highlightColor: Colors.black.withOpacity(0.7),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              direction: Axis.horizontal,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 75),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(64.0),
                      color: isHover
                          ? MyColors.bgTintPink.withOpacity(0.7)
                          : Colors.transparent),
                  child: SvgPicture.string(
                    widget.isSelected
                        ? (widget.stringSvgSelected == null
                            ? widget.stringSvg
                            : widget.stringSvgSelected!)
                        : widget.stringSvg,
                    height: widget.iconSize,
                    width: widget.iconSize,
                    colorFilter: widget.isSelected
                        ? const ColorFilter.mode(
                            MyColors.bgSelectedBlue, BlendMode.srcIn)
                        : null,
                  ),
                ),
                Visibility(
                  visible: widget.textVisibilty,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: widget.paddingIconText),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isHover
                              ? MyColors.bgTintPink
                              : widget.isSelected
                                  ? MyColors.bgSelectedBlue
                                  : Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
