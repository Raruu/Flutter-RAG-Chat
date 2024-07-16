import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/my_colors.dart';

class PinkTextField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final String? strIconLeft;
  final double? iconSizeLeft;
  final double? iconSizeRight;
  final String? strIconRight;
  final Function()? leftButtonFunc;
  final Function()? rightButtonFunc;
  final Function()? onEditingComplete;
  final Function(String value)? onChanged;
  final TextEditingController? textEditingController;
  final double borderRadiusCircular;
  final bool multiLine;
  final Color backgroundColor;
  final bool newLineOnEnter;

  const PinkTextField({
    super.key,
    this.hintText = 'Fill Me',
    this.strIconLeft,
    this.strIconRight,
    this.leftButtonFunc,
    this.rightButtonFunc,
    this.onChanged,
    this.textEditingController,
    this.iconSizeLeft,
    this.iconSizeRight,
    this.borderRadiusCircular = 12.0,
    this.onEditingComplete,
    this.multiLine = false,
    this.labelText,
    this.backgroundColor = MyColors.bgTintPink,
    this.newLineOnEnter = true,
  });

  @override
  State<PinkTextField> createState() => _PinkTextFieldState();
}

class _PinkTextFieldState extends State<PinkTextField> {
  late final FocusNode _focus;
  bool isFocused = false;

  @override
  void initState() {
    _focus = FocusNode(
      onKeyEvent: widget.newLineOnEnter
          ? null
          : (node, event) {
              if (event is KeyDownEvent &&
                  event.physicalKey == PhysicalKeyboardKey.enter &&
                  !HardwareKeyboard.instance.isShiftPressed) {
                widget.onEditingComplete?.call();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
    );
    _focus.addListener(
      () => setState(() {
        isFocused = _focus.hasFocus;
      }),
    );
    super.initState();
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType:
          widget.multiLine ? TextInputType.multiline : TextInputType.text,
      maxLines: widget.multiLine ? null : 1,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      controller: widget.textEditingController,
      focusNode: _focus,
      style: const TextStyle(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        // floatingLabelBehavior: FloatingLabelBehavior.always,
        // alignLabelWithHint: true,
        labelText: widget.labelText,
        prefixIcon: widget.strIconLeft == null
            ? null
            : Align(
                widthFactor: 1,
                heightFactor: 1,
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 16.0,
                  ),
                  child: IconButton(
                    onPressed: widget.leftButtonFunc,
                    icon: SvgPicture.string(
                      widget.strIconLeft!,
                      width: widget.iconSizeLeft,
                      height: widget.iconSizeLeft,
                      colorFilter: isFocused
                          ? null
                          : ColorFilter.mode(
                              Colors.black.withOpacity(0.5), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
        suffixIcon: widget.strIconRight == null
            ? null
            : Align(
                widthFactor: 1,
                heightFactor: 1,
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 16.0),
                  child: IconButton(
                    onPressed: widget.rightButtonFunc,
                    icon: SvgPicture.string(
                      widget.strIconRight!,
                      width: widget.iconSizeRight,
                      height: widget.iconSizeRight,
                      colorFilter: isFocused
                          ? null
                          : ColorFilter.mode(
                              Colors.black.withOpacity(0.5), BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
        hintStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
        hintText: widget.hintText,
        border: OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(widget.borderRadiusCircular)),
            borderSide: BorderSide.none),
        fillColor: widget.backgroundColor,
        filled: true,
      ),
    );
  }
}
