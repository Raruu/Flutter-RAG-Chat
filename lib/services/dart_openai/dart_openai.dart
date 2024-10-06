import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_rag_chat/models/chat_data_list.dart';
import 'package:flutter_rag_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base_model.dart';
import 'data.dart';
import 'settings_widget.dart';

class DartOpenai extends BaseModel {
  @override
  Map<String, dynamic> get defaultParameters => {
        "frequency_penalty": [-2.0, 0.0, 2.0],
        // "logit_bias": [-100, 0, 100],
        // "logprobs": [false],
        // "top_logprobs": [0, 0, 20],
        "max_tokens": [0, 256, 4096],
        // "n": [0, 1, 10],
        "presence_penalty": [-2.0, 0.0, 2.0],
        "temperature": [0.001, 1.0, 2.0],
        "top_p": [0.0, 1.0, 1.0],
      };

  static DartOpenai? _instance;
  factory DartOpenai(
    dynamic Function() notifyListenersLLM,
    SharedPreferences prefs,
    ChatDataList chatDataList,
  ) {
    _instance ??= DartOpenai._internal(notifyListenersLLM, prefs, chatDataList);
    return _instance!;
  }

  late final Data _data;

  DartOpenai._internal(
      super.notifyListenerLLM, super.prefs, super.chatDataList) {
    _data = Data(super.prefs, super.notifyListenerLLM);
  }

  @override
  Widget get widgetLlmodelSetting => SettingsWidget(
        valueLabel: 'Model',
        intialURL: _data.baseURL,
        intialApi: _data.apiKey,
        onSetURL: (value) => _data.baseURL = value,
        onSetAPI: (value) => _data.apiKey = value,
        modelValue: _data.llmModel,
        onChangeModel: (value) => _data.llmModel = value,
        onRefreshModelList: () => _data.getModelList(),
        modelList: _data.models
            ?.where((element) => element.id.contains('gpt'))
            .map((e) => e.id)
            .toList(),
      );

  // @override
  // Widget get widgetEmbeddingmodelSetting => SettingsWidget(
  //       valueLabel: 'Model',
  //       intialURL: 'intialURL',
  //       intialValue: 'intialValue',
  //       onSetURL: (value) {},
  //       onUnsetValue: () {},
  //       onSetValue: (value) {},
  //       availabValueRefresh: () {},
  //       suggestionsCallback: (search) {},
  //     );

  @override
  Future? addKnowledge(value, {String? webFileName}) {
    // TODO: implement addKnowledge
    throw UnimplementedError();
  }

  @override
  Future? deleteKnowledge(String filename) {
    // TODO: implement deleteKnowledge
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>?> generateText(
      {required String prompt,
      required int seed,
      required Map<String, dynamic> parameters}) async {
    final currentData = chatDataList.currentData;

    final requestMessages = [
      if (currentData.usePreprompt[0])
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              currentData.prePrompt ?? '',
            ),
          ],
        ),
      if (currentData.useChatConversationContext[0])
        ...List.generate(
          currentData.messageList.length - 1,
          (index) => OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                currentData.messageList[index].message,
              ),
            ],
            role: currentData.messageList[index].role == MessageRole.model
                ? OpenAIChatMessageRole.assistant
                : OpenAIChatMessageRole.user,
          ),
        ),
      OpenAIChatCompletionChoiceMessageModel(
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(
              currentData.knowledges.isNotEmpty
                  // TODO Knowledge
                  ? 'Context1:\n\nUser Query: $prompt'
                  : 'User Query: $prompt'),
        ],
        role: OpenAIChatMessageRole.user,
      ),
    ];

    OpenAIChatCompletionModel chatCompletion =
        await OpenAI.instance.chat.create(
      model: _data.llmModel ?? '',
      responseFormat: {"type": "json_object"},
      seed: seed,
      messages: requestMessages,
      frequencyPenalty: parameters['frequency_penalty'],
      // logitBias: parameters['logit_bias'],
      presencePenalty: parameters['presence_penalty'],
      maxTokens: parameters['max_tokens'],
      temperature: parameters['temperature'],
      topP: parameters['top_p'],
    );

    // print('ChatCompletion: $chatCompletion');
    // print(chatCompletion.choices.first.message); // ...
    // print(chatCompletion.systemFingerprint); // ...
    // print(chatCompletion.usage.promptTokens); // ...
    // print(chatCompletion.id);

    return {
      'context1': null,
      'context2': null,
      'query': prompt,
      'seed': seed.toString(),
      'generated_text': chatCompletion.choices.first.message,
    };
  }

  @override
  Future? onChatSettingsChanged() {
    // TODO: implement onChatSettingsChanged
    throw UnimplementedError();
  }

  @override
  Future? resetKnowledge() {
    // TODO: implement resetKnowledge
    throw UnimplementedError();
  }

  @override
  Future? setKnowledge(List<Map<String, dynamic>> knowledges) {
    // TODO: implement setKnowledge
    throw UnimplementedError();
  }
}
