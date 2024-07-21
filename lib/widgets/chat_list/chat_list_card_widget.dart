import "package:flutter/material.dart";
import 'package:flutter_svg/flutter_svg.dart';

import '../../utils/my_colors.dart';
import '../../utils/svg_icons.dart';

class ChatListCardWidget extends StatefulWidget {
  final String chatTitle;
  final String chatSubtitle;
  final Color splashColor;
  final Color hoverColor;
  final Color selectedColor;
  final bool isSelected;
  final Function()? onTap;
  final Widget? rightWidget;
  final Widget? rightWidgetOnHover;
  final bool isShowExpandedChild;
  final double heightOfExpandedChild;
  final Widget? expandedChild;
  final Curve expandingCurve;
  final Duration expandDuration;
  final MouseCursor? mouseCursor;
  const ChatListCardWidget({
    super.key,
    this.chatTitle = 'Title Chat',
    this.chatSubtitle = 'Anone anone anone',
    this.rightWidget,
    this.hoverColor = Colors.white,
    this.selectedColor = MyColors.bgSelectedBlue,
    this.isSelected = false,
    this.onTap,
    this.rightWidgetOnHover,
    this.expandedChild,
    this.isShowExpandedChild = false,
    this.heightOfExpandedChild = 100,
    this.expandingCurve = Curves.bounceOut,
    this.splashColor = MyColors.bgTintPink,
    this.expandDuration = const Duration(milliseconds: 700),
    this.mouseCursor,
  });

  @override
  State<ChatListCardWidget> createState() => _ChatListCardWidgetState();
}

class _ChatListCardWidgetState extends State<ChatListCardWidget> {
  late bool isHover;
  void setIsHover(bool value) => setState(() => isHover = value);

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
        child: AnimatedContainer(
          duration: widget.expandDuration,
          curve: widget.expandingCurve,
          clipBehavior: Clip.antiAlias,
          height: widget.isShowExpandedChild
              ? 71 + widget.heightOfExpandedChild
              : 71,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: widget.isSelected ? widget.selectedColor : Colors.white,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              mouseCursor: widget.mouseCursor,
              onTap: widget.onTap,
              splashColor: widget.splashColor,
              highlightColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverDuration: const Duration(milliseconds: 200),
              hoverColor:
                  widget.isSelected ? widget.selectedColor : widget.hoverColor,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedOpacity(
                      opacity: widget.isShowExpandedChild ? 1 : 0,
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.linear,
                      child: widget.expandedChild,
                    ),
                  ),
                  Container(
                      height: 71,
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.transparent,
                      child: upperWidget()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Row upperWidget() {
    return Row(
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
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
              const Spacer(),
              Text(
                widget.chatSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w300, fontSize: 16),
              )
            ],
          ),
        ),
        if (widget.rightWidget != null)
          isHover && widget.rightWidgetOnHover != null
              ? widget.rightWidgetOnHover!
              : widget.rightWidget!,
      ],
    );
  }
}
