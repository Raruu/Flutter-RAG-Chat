import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/widgets/nice_button.dart';

import '../../../widgets/pink_textfield.dart';
import '../../../utils/my_colors.dart';
import '../../../utils/svg_icons.dart';
import 'data.dart';

class SettingsWidget extends StatefulWidget {
  final String? modelName;
  final Data data;
  final String valueLabel;
  final String intialURL;
  final String intialValue;
  final Function(String value) onSetURL;
  final Function(String value) onSetValue;
  final Function() onUnsetValue;
  final Function() availabValueRefresh;

  final FutureOr<List<Object?>?> Function(String search)? suggestionsCallback;
  const SettingsWidget({
    super.key,
    required this.valueLabel,
    required this.intialURL,
    required this.intialValue,
    required this.onSetURL,
    required this.onUnsetValue,
    required this.onSetValue,
    this.suggestionsCallback,
    required this.data,
    required this.availabValueRefresh,
    this.modelName,
  });

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late final TextEditingController urlTextEditingController;
  late final TextEditingController valueEditingController;
  @override
  void initState() {
    super.initState();
    urlTextEditingController = TextEditingController(text: widget.intialURL);
    valueEditingController = TextEditingController(text: widget.intialValue);
  }

  @override
  void dispose() {
    urlTextEditingController.dispose();
    valueEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PinkTextField(
          showBorderWhenFocus: true,
          textEditingController: urlTextEditingController,
          tooltipIconRight: 'Set',
          hintText: '',
          labelText: 'URL',
          backgroundColor: MyColors.bgTintBlue,
          strIconRight: SvgIcons.fluentSaveSync,
          rightButtonFunc: () => widget.onSetURL(urlTextEditingController.text),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            widget.modelName == null
                ? 'Disconnected'
                : 'Model:\n${widget.modelName!}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
        PinkTextField.typeAhead(
          showBorderWhenFocus: true,
          textEditingController: valueEditingController,
          hintText: '',
          labelText: widget.valueLabel,
          backgroundColor: MyColors.bgTintPink,
          strIconRight: SvgIcons.fluentSync,
          tooltipIconRight: 'Refresh',
          rightButtonFunc: () => widget.availabValueRefresh(),
          onSelected: (value) => valueEditingController.text = value.toString(),
          suggestionsCallback: widget.suggestionsCallback,
          typeAheadTileColor: MyColors.bgTintPink,
        ),
        const Padding(
          padding: EdgeInsets.all(4),
        ),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: NiceButton(
                onTap: () => widget.onSetValue(valueEditingController.text),
                text: '   Load   ',
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(4),
            ),
            Flexible(
              fit: FlexFit.tight,
              child: NiceButton(
                  onTap: () => widget.onUnsetValue(), text: 'Un-Load'),
            )
          ],
        ),
      ],
    );
  }
}
