import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/models/chat_data_list.dart';
import 'package:flutter_rag_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../base_model.dart';
import 'data.dart';
import 'settings_widget.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class GoogleGemini extends BaseModel {
  @override
  Map<String, dynamic> get defaultParameters => {
        "temperature": [0.001, 1.0, 2.0],
        "max_output_tokens": [1, 256, 4096],
        "top_k": [0, 50, 200],
        "top_p": [0.0, 1.0, 1.0],
      };

  static GoogleGemini? _instance;
  factory GoogleGemini(
    dynamic Function() notifyListenersLLM,
    SharedPreferences prefs,
    ChatDataList chatDataList,
  ) {
    _instance ??=
        GoogleGemini._internal(notifyListenersLLM, prefs, chatDataList);
    return _instance!;
  }

  late final Data _data;
  GoogleGemini._internal(
      super.notifyListenerLLM, super.prefs, super.chatDataList) {
    _data = Data(super.prefs);
  }

  @override
  Widget? get widgetLlmodelSetting => SettingsWidget(
        valueLabel: "valueLabel",
        intialURL: "",
        intialApi: _data.apiKey,
        onSetURL: (value) {},
        onChangeModel: (value) {},
        onRefreshModelList: () {},
        onSetAPI: (value) => _data.apiKey = value,
        modelList: _data.geminiModels?.map((e) => e.name ?? "").toList(),
      );

  @override
  Future? addKnowledge(value, {String? webFileName}) {
    return null;
  }

  @override
  Future? deleteKnowledge(String filename) {
    return null;
  }

  @override
  Future<Map<String, dynamic>?> generateText(
      {required String prompt,
      required int seed,
      required Map<String, dynamic> parameters}) async {
    final gemini = Gemini.instance;
    final currentData = chatDataList.currentData;

    var geminiCandidate = await gemini.chat([
      if (currentData.usePreprompt[0])
        Content(parts: [Parts(text: currentData.prePrompt)], role: 'user'),
      if (currentData.useChatConversationContext[0])
        ...List.generate(
          currentData.messageList.length - 1,
          (index) => Content(
              parts: [Parts(text: currentData.messageList[index].message)],
              role: currentData.messageList[index].role == MessageRole.model
                  ? 'model'
                  : 'user'),
        ),
      Content(parts: [Parts(text: prompt)], role: 'user'),
    ],
        generationConfig: GenerationConfig(
          temperature: parameters['temperature'],
          maxOutputTokens: parameters['max_output_tokens'],
          topP: parameters['top_p'],
          topK: parameters['top_k'],
        ));

    return {
      'context1': null,
      'context2': null,
      'query': prompt,
      'seed': seed.toString(),
      'generated_text': geminiCandidate?.output ?? "NULL",
    };
  }

  @override
  Future? onChatSettingsChanged() {
    return null;
  }

  @override
  Future? resetKnowledge() {
    return null;
  }

  @override
  Future? setKnowledge(List<Map<String, dynamic>> knowledges) {
    return null;
  }
}
