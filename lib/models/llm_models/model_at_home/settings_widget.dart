import 'package:flutter/material.dart';

import '../../../widgets/pink_textfield.dart';
import '../../../utils/my_colors.dart';
import '../../../utils/svg_icons.dart';
import 'data.dart';
// import '../../../widgets/nice_drop_down_button.dart';

class SettingsWidget extends StatefulWidget {
  final Data data;
  const SettingsWidget({
    super.key,
    required this.data,
  });

  @override
  State<SettingsWidget> createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  late final TextEditingController urlTextEditingController;
  @override
  void initState() {
    super.initState();
    urlTextEditingController = TextEditingController()
      ..text = widget.data.baseURL;
  }

  @override
  void dispose() {
    urlTextEditingController.dispose();
    super.dispose();
  }

  int modelFrom = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PinkTextField(
          textEditingController: urlTextEditingController,
          hintText: '',
          labelText: 'URL',
          backgroundColor: MyColors.bgTintBlue,
          strIconRight: SvgIcons.fluentSaveSync,
          rightButtonFunc: () =>
              widget.data.baseURL = urlTextEditingController.text,
        ),
        const Padding(padding: EdgeInsets.all(4)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ...List.generate(
              2,
              (index) {
                var label = ['OnServer', 'HuggingFace'];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.0),
                  child: ChoiceChip(
                    label: Text(label[index]),
                    selected: modelFrom == index,
                    onSelected: (value) => setState(() {
                      modelFrom = index;
                    }),
                  ),
                );
              },
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(4)),
        modelFrom == 0 ? Text('Not Implemented') : Text('Not Implemented')
        // : PinkTextField(
        //     hintText: '',
        //     labelText: 'Model',
        //     backgroundColor: MyColors.bgTintBlue,
        //     strIconRight: SvgIcons.fluentSaveSync,
        //     rightButtonFunc: () {

        //     },
        //   )
      ],
    );
  }
}
