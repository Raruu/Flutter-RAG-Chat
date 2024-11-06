import 'package:flutter/material.dart';

import '../../widgets/nice_drop_down_button.dart';
import '../../widgets/pink_textfield.dart';
import '../../utils/my_colors.dart';
import '../../utils/svg_icons.dart';

class SettingsWidget extends StatefulWidget {
  final String valueLabel;
  final String intialURL;
  final String intialApi;
  final Function(String value) onSetURL;
  final Function(String value) onSetAPI;
  final String? modelValue;
  final Function(String value) onChangeModel;
  final Function() onRefreshModelList;
  final List<String>? modelList;

  const SettingsWidget({
    super.key,
    required this.valueLabel,
    required this.intialURL,
    required this.intialApi,
    required this.onSetURL,
    required this.onChangeModel,
    this.modelList,
    required this.onRefreshModelList,
    required this.onSetAPI,
    this.modelValue,
  });

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late final TextEditingController urlTextEditingController;
  late final TextEditingController apiTextEditingController;
  @override
  void initState() {
    super.initState();
    urlTextEditingController = TextEditingController(text: widget.intialURL);
    apiTextEditingController = TextEditingController(text: widget.intialApi);
  }

  @override
  void dispose() {
    urlTextEditingController.dispose();
    apiTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'THIS IS ABANDONED',
          style: TextStyle(fontSize: 20),
        ),
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
        const Padding(padding: EdgeInsets.all(4.0)),
        PinkTextField(
          showBorderWhenFocus: true,
          textEditingController: apiTextEditingController,
          tooltipIconRight: 'Set',
          hintText: '',
          labelText: 'API-KEY',
          backgroundColor: MyColors.bgTintBlue,
          strIconRight: SvgIcons.fluentSaveSync,
          rightButtonFunc: () => widget.onSetAPI(apiTextEditingController.text),
        ),
        const Padding(padding: EdgeInsets.all(4.0)),
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: NiceDropDownButton(
                value: widget.modelValue,
                hintText: 'Model',
                items: widget.modelList == null
                    ? null
                    : List.generate(
                        widget.modelList!.length,
                        (index) => DropdownMenuItem(
                          value: widget.modelList![index],
                          child: Text(widget.modelList![index]),
                        ),
                      ).toList(),
                onChanged: (value) => widget.onChangeModel(value),
              ),
            ),
            const Padding(padding: EdgeInsets.all(4.0)),
            IconButton(
                onPressed: () {
                  widget.onRefreshModelList();
                  setState(() {});
                },
                icon: const Icon(Icons.refresh))
          ],
        )
      ],
    );
  }
}
