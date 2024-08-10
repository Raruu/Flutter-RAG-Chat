import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/models/llm_model.dart';
import 'package:flutter_rag_chat/widgets/chat_config/parameter_bool.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/svg_icons.dart';
import '../utils/util.dart';
import 'nice_drop_down_button.dart';

class GeneralSettings extends StatefulWidget {
  final LLMModel llmModel;
  final Function() toggleDarkMode;
  const GeneralSettings({
    super.key,
    required this.llmModel,
    required this.toggleDarkMode,
  });

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Settings',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Utils.getDefaultTextColor(context)),
          ),
        ),
        ParameterBool(
          textKey: 'DarkMode',
          onChanged: (value) => widget.toggleDarkMode(),
          setStateOnValueChange: false,
          value: [Theme.of(context).colorScheme.brightness == Brightness.dark],
        ),
        Row(
          children: [
            SvgPicture.string(
              SvgIcons.modelIcon,
              colorFilter: ColorFilter.mode(
                Utils.getDefaultTextColor(context)!,
                BlendMode.srcIn,
              ),
            ),
            const Text(
              'Model Provider',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          child: Column(
            children: [
              NiceDropDownButton(
                value: widget.llmModel.provider,
                items: widget.llmModel.providersList
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) => widget.llmModel.provider = value,
              ),
              const Padding(padding: EdgeInsets.all(4)),
              widget.llmModel.settingsWidget
            ],
          ),
        )
      ],
    );
  }
}
