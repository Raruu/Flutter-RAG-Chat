import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

import 'settings_widget.dart';
import 'data.dart';
import '../../models/chat_data_list.dart';
import '../../models/message.dart';
import '../base_model.dart';

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
  Future<Map<String, dynamic>?> generateText({
    required String query,
    required int seed,
    required Map<String, dynamic> parameters,
    Map<String, dynamic>? retrievalContext,
  }) async {
    final gemini = Gemini.instance;
    final currentData = chatDataList.currentData;

    List<dynamic>? context1;
    List<String>? knowledges;
    if (retrievalContext != null && retrievalContext['context1'] != "") {
      context1 = retrievalContext['context1'];
      for (var knowledgeData in context1!) {
        knowledges ??= List.empty(growable: true);
        knowledges.add(knowledgeData['context']);
      }
    }

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
      if (knowledges != null)
        Content(parts: [
          Parts(text: "context:\n${knowledges.join(" ")}\n\n $query")
        ], role: 'user')
      else
        Content(parts: [Parts(text: query)], role: 'user'),
    ],
        generationConfig: GenerationConfig(
          temperature: parameters['temperature'],
          maxOutputTokens: parameters['max_output_tokens'],
          topP: parameters['top_p'],
          topK: parameters['top_k'],
        ));

    return {
      'context1': context1,
      'context2': null,
      'query': query,
      'seed': seed.toString(),
      'generated_text': geminiCandidate?.output ?? "NULL",
    };
  }
}
