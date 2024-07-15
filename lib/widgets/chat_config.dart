import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/utils/my_colors.dart';

import 'chat_config/chat_config_card.dart';
import '../models/llm_model.dart';
import '../utils/svg_icons.dart';
import 'chat_config/parameter_slider.dart';
import 'chat_config/parameter_bool.dart';
import '../models/chat_data_list.dart';
import 'nice_button.dart';

class ChatConfig extends StatefulWidget {
  final LLMModel llmModel;
  final ChatDataList chatDataList;
  const ChatConfig({
    super.key,
    required this.llmModel,
    required this.chatDataList,
  });

  @override
  State<ChatConfig> createState() => _ChatConfigState();
}

class _ChatConfigState extends State<ChatConfig> {
  late List<Widget> parameters;

  void parametersInit() {
    parameters = [];

    var savedParameters = widget.llmModel.parameters;
    widget.llmModel.defaultParameters?.forEach(
      (key, value) {
        parametersOnChanged(paramChangedValue) {
          widget.llmModel.parameters?[key] = paramChangedValue;
          widget.chatDataList.currentData.parameters[key] = paramChangedValue;
        }

        Type runTimeType = value.runtimeType;
        if ((runTimeType == List<double>) || (runTimeType == List<int>)) {
          if (savedParameters != null) {
            value[1] = savedParameters[key];
          }
          parameters.add(ParameterSlider(
            textKey: key,
            values: value,
            onChanged: parametersOnChanged,
          ));
        } else if (runTimeType == List<bool>) {
          if (savedParameters != null) {
            value.first = savedParameters[key];
          }
          parameters.add(ParameterBool(
            textKey: key,
            value: value,
            onChanged: parametersOnChanged,
          ));
        }
      },
    );

    parameters.add(NiceButton(
      onTap: () {
        widget.llmModel.defaultParameters?.forEach((key, value) {
          parametersOnChanged(paramChangedValue) {
            widget.llmModel.parameters?[key] = paramChangedValue;
            widget.chatDataList.currentData.parameters[key] = paramChangedValue;
          }

          Type runTimeType = value.runtimeType;
          if ((runTimeType == List<double>) || (runTimeType == List<int>)) {
            parametersOnChanged(value[1]);
          } else if (runTimeType == List<bool>) {
            parametersOnChanged(value.first);
          }
        });

        setState(() => parametersInit());
      },
      text: 'Reset',
      borderRadiusCircular: 12,
      hoverColor: Colors.red,
      splashColor: MyColors.bgTintBlue,
      backgroundColor: Colors.transparent,
      hoverDuration: const Duration(milliseconds: 200),
      border: Border.all(
        color: Colors.red,
      ),
      textHoverColor: Colors.white,
    ));
  }

  @override
  void initState() {
    parametersInit();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // print('aaaa: ${widget.llmModel.parameters}');
    parametersInit();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            ChatConfigCard(
              title: 'CHAT PARAMETERS',
              strIcon: SvgIcons.fluentSettingsReguler,
              children: parameters,
            ),
            const ChatConfigCard(
              title: 'CUSTOM PROMPT',
              strIcon: SvgIcons.fluentPromptReguler,
              children: [Text('Not Implemented')],
            ),
            const ChatConfigCard(
              title: 'KNOWLEDGE',
              strIcon: SvgIcons.knowledge,
              children: [Text('Not Implemented')],
            ),
          ],
        ),
      ),
    );
  }
}
