import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/utils/my_colors.dart';
import 'package:flutter_rag_chat/utils/util.dart';

import 'chat_config/chat_config_card.dart';
import '../models/llm_model.dart';
import '../utils/svg_icons.dart';
import 'chat_config/parameter_slider.dart';
import 'chat_config/parameter_bool.dart';
import '../models/chat_data_list.dart';
import 'nice_button.dart';
import 'pink_textfield.dart';

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
      text: 'RESET',
      borderRadiusCircular: 30,
      hoverColor: Colors.red,
      splashColor: MyColors.bgTintBlue,
      backgroundColor: Colors.transparent,
      hoverDuration: const Duration(milliseconds: 200),
      border: Border.all(
        color: Colors.red,
      ),
      textColor: Colors.red,
      textHoverColor: Colors.white,
    ));
  }

  late final TextEditingController _prePromptTextController;

  @override
  void initState() {
    parametersInit();
    _prePromptTextController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _prePromptTextController.dispose();
    super.dispose();
  }

  void loadPrePrompt() {
    widget.chatDataList.currentData.prePrompt ??=
        widget.llmModel.defaultPrePrompt;
    _prePromptTextController.text = widget.chatDataList.currentData.prePrompt!;
  }

  @override
  Widget build(BuildContext context) {
    parametersInit();
    loadPrePrompt();
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
            prePrompt(context),
            ChatConfigCard(
              title: 'KNOWLEDGE',
              strIcon: SvgIcons.knowledge,
              children: [
                ParameterBool(
                    textKey: 'Use Chat Conversation Context',
                    onChanged: (value) => setState(() {
                          widget.chatDataList.currentData
                              .useChatConversationContext[0] = value;
                        }),
                    value: widget
                        .chatDataList.currentData.useChatConversationContext),
                const Text('Not Implemented'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ChatConfigCard prePrompt(BuildContext context) {
    return ChatConfigCard(
      title: 'PRE-PROMPT',
      strIcon: SvgIcons.fluentPromptReguler,
      onExpansionChanged: (value) {
        if (value) {
          loadPrePrompt();
        }
      },
      children: [
        ParameterBool(
            textKey: 'Use Pre-Prompt',
            onChanged: (value) => setState(() {
                  widget.chatDataList.currentData.usePreprompt[0] = value;
                }),
            value: widget.chatDataList.currentData.usePreprompt),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: widget.chatDataList.currentData.usePreprompt[0] ? 1 : 0.5,
          child: AbsorbPointer(
            absorbing: !widget.chatDataList.currentData.usePreprompt[0],
            child: Column(
              children: [
                Container(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 2 / 3),
                  child: PinkTextField(
                    textEditingController: _prePromptTextController,
                    hintText: '',
                    labelText: 'PRE-PROMPT',
                    backgroundColor: MyColors.bgTintBlue,
                    multiLine: true,
                    onChanged: (value) {},
                  ),
                ),
                const Padding(padding: EdgeInsets.all(5.0)),
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 50,
                      child: NiceButton(
                        onTap: () {
                          widget.chatDataList.currentData.prePrompt =
                              _prePromptTextController.text;
                          Utils.showSnackBar(context,
                              title: 'Success',
                              duration: const Duration(milliseconds: 100),
                              subTitle: 'Task Complete Onii-chan~');
                        },
                        text: 'UPDATE',
                        padding: const EdgeInsets.all(0),
                        borderRadiusCircular: 30,
                        backgroundColor: MyColors.bgTintPink,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(2.0)),
                    SizedBox(
                      width: 90,
                      height: 50,
                      child: NiceButton(
                        onTap: loadPrePrompt,
                        padding: const EdgeInsets.all(0),
                        text: 'UNDO',
                        borderRadiusCircular: 30,
                        hoverColor: Colors.red,
                        splashColor: MyColors.bgTintBlue,
                        backgroundColor: Colors.transparent,
                        hoverDuration: const Duration(milliseconds: 200),
                        border: Border.all(
                          color: Colors.red,
                        ),
                        textColor: Colors.red,
                        textHoverColor: Colors.white,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(2.0)),
                    SizedBox(
                      width: 100,
                      height: 50,
                      child: NiceButton(
                        onTap: () {
                          _prePromptTextController.text =
                              widget.llmModel.defaultPrePrompt;
                        },
                        padding: const EdgeInsets.all(0),
                        text: 'RESET',
                        borderRadiusCircular: 30,
                        hoverColor: Colors.red,
                        splashColor: MyColors.bgTintBlue,
                        backgroundColor: Colors.transparent,
                        hoverDuration: const Duration(milliseconds: 200),
                        border: Border.all(
                          color: Colors.red,
                        ),
                        textColor: Colors.red,
                        textHoverColor: Colors.white,
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
