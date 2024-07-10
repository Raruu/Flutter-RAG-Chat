import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/my_colors.dart';
import '../../utils/svg_icons.dart';

class ChatListCardWidget extends StatefulWidget {
  final String chatTitle;
  final String chatSubtitle;
  final Widget? rightWidget;
  final Color hoverColor;
  final Color selectedColor;
  final bool isSelected;
  final Function()? onTap;
  const ChatListCardWidget({
    super.key,
    this.chatTitle = 'Title Chat',
    this.chatSubtitle = 'Anone anone anone',
    this.rightWidget,
    this.hoverColor = Colors.white,
    this.selectedColor = MyColors.bgSelectedBlue,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<ChatListCardWidget> createState() => _ChatListCardWidgetState();
}

class _ChatListCardWidgetState extends State<ChatListCardWidget> {
  late bool isHover;
  void setIsHover(bool value) =>
      setState(() => isHover = widget.isSelected ? widget.isSelected : value);

  @override
  void initState() {
    isHover = widget.isSelected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (event) => setIsHover(true),
      onExit: (event) => setIsHover(false),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Container(
          clipBehavior: Clip.antiAlias,
          height: 71,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: widget.isSelected ? widget.selectedColor : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: MyColors.bgTintPink,
              hoverDuration: const Duration(milliseconds: 200),
              hoverColor:
                  widget.isSelected ? widget.selectedColor : widget.hoverColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: MyColors.bgTintBlue,
                      ),
                      child: SvgPicture.string(
                        SvgIcons.chatBold,
                        width: 26,
                        height: 26,
                        colorFilter: const ColorFilter.mode(
                            Colors.black, BlendMode.srcIn),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(5)),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.chatTitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 20),
                          ),
                          const Spacer(),
                          Text(
                            widget.chatSubtitle,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w300, fontSize: 16),
                          )
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (widget.rightWidget != null) widget.rightWidget!,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
