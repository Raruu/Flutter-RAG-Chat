import 'dart:async';

import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import '../utils/my_colors.dart';

class PinkTextField extends StatefulWidget {
  final String hintText;
  final String? labelText;
  final Color labelColor;
  final Color floatingLabelColor;
  final String? strIconLeft;
  final String? tooltipIconLeft;
  final double? iconSizeLeft;
  final String? strIconRight;
  final String? tooltipIconRight;
  final double? iconSizeRight;
  final Function()? leftButtonFunc;
  final Function()? rightButtonFunc;
  final Function()? onEditingComplete;
  final Function(String value)? onChanged;
  final TextEditingController? textEditingController;
  final double borderRadiusCircular;
  final bool multiLine;
  final Color backgroundColor;
  final bool newLineOnEnter;
  final TextInputType? textInputType;
  final TextAlign textAlign;
  final FocusNode? focusNode;
  final bool showBorderWhenFocus;
  final Color? typeAheadTileColor;
  final int? maxLength;

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
    this.tooltipIconLeft,
    this.tooltipIconRight,
    this.textInputType,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.floatingLabelColor = MyColors.bgTintBlue,
    this.showBorderWhenFocus = false,
    this.labelColor = MyColors.textTintBlue,
    this.maxLength,
  })  : typeAhead = false,
        onSelected = null,
        suggestionsCallback = null,
        typeAheadTileColor = null;

  final bool typeAhead;
  final Function(Object? value)? onSelected;
  final FutureOr<List<Object?>?> Function(String search)? suggestionsCallback;
  const PinkTextField.typeAhead({
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
    this.tooltipIconLeft,
    this.tooltipIconRight,
    this.textInputType,
    this.textAlign = TextAlign.start,
    this.focusNode,
    this.floatingLabelColor = MyColors.bgTintBlue,
    this.showBorderWhenFocus = false,
    required this.onSelected,
    required this.suggestionsCallback,
    this.labelColor = MyColors.textTintBlue,
    this.typeAheadTileColor,
    this.maxLength,
  }) : typeAhead = true;

  @override
  State<PinkTextField> createState() => _PinkTextFieldState();
}

class _PinkTextFieldState extends State<PinkTextField> {
  late final FocusNode _focus;
  bool isFocused = false;

  @override
  void initState() {
    _focus = widget.focusNode ?? FocusNode();
    _focus.onKeyEvent = widget.newLineOnEnter
        ? null
        : (node, event) {
            if (event is KeyDownEvent &&
                event.physicalKey == PhysicalKeyboardKey.enter &&
                !HardwareKeyboard.instance.isShiftPressed) {
              widget.onEditingComplete?.call();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          };
    _focus.addListener(
      () => setState(() {
        isFocused = _focus.hasFocus;
      }),
    );
    super.initState();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.typeAhead
        ? TypeAheadField(
            controller: widget.textEditingController,
            focusNode: _focus,
            builder: (context, controller, focusNode) =>
                pinkTextfield(controller, focusNode),
            itemBuilder: (context, value) => ListTile(
              title: Text(
                value.toString(),
                style: const TextStyle(color: Colors.black),
              ),
              tileColor: widget.typeAheadTileColor,
            ),
            onSelected: (value) {
              widget.textEditingController?.text = value.toString();
              widget.onSelected?.call(value);
            },
            suggestionsCallback: widget.suggestionsCallback!,
            decorationBuilder: (context, child) => Material(
              type: MaterialType.card,
              clipBehavior: Clip.antiAlias,
              elevation: 4,
              borderRadius: BorderRadius.circular(10),
              child: child,
            ),
          )
        : pinkTextfield(widget.textEditingController, _focus);
  }

  TextField pinkTextfield(
      TextEditingController? textEditingController, FocusNode focusNode) {
    return TextField(
      textAlign: widget.textAlign,
      keyboardType: widget.textInputType ??
          (widget.multiLine ? TextInputType.multiline : TextInputType.text),
      inputFormatters: widget.textInputType == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp('[0-9.,-]'))]
          : null,
      maxLength: widget.maxLength,
      maxLines: widget.multiLine ? null : 1,
      onEditingComplete: widget.onEditingComplete,
      onChanged: widget.onChanged,
      controller: textEditingController,
      focusNode: focusNode,
      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(widget.borderRadiusCircular)),
          borderSide: widget.showBorderWhenFocus
              ? const BorderSide(
                  color: MyColors.textTintPink,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignInside)
              : BorderSide.none,
        ),
        labelText: widget.labelText,
        labelStyle: TextStyle(color: widget.labelColor),
        floatingLabelStyle: TextStyle(
            color: widget.floatingLabelColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(color: Colors.black, blurRadius: 3)]),
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
                    tooltip: widget.tooltipIconLeft,
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
                    tooltip: widget.tooltipIconRight,
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
            color: MyColors.textTintPink),
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
