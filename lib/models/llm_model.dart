import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/models/chat_data.dart';
import 'package:flutter_rag_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm_models/model_at_home.dart';
import 'llm_models/base_model.dart';
import '../utils/util.dart';
import './llm_models/default_preprompt.dart' as df_preprompt;

class LLMModel extends ChangeNotifier {
  BuildContext? context;
  late final SharedPreferences prefs;
  BaseModel? _llmModel;
  Map<String, dynamic>? get defaultParameters => _llmModel?.defaultParameters;
  String get defaultPrePrompt => df_preprompt.defaultPrePrompt;
  Widget get settingsWidget =>
      _llmModel?.settingsWidget ?? const LinearProgressIndicator();
  Widget get informationWidget =>
      _llmModel?.informationWidget ?? const SizedBox();

  Map<String, dynamic>? _parameters;
  Map<String, dynamic>? get parameters => _parameters;

  final List<String> providersList = [
    'OpenAI',
    // 'Google',
    // 'Text-Generation-Webui',
    'Model at home',
  ];

  String? _provider;
  String? get provider => _provider;
  set provider(String? value) {
    switch (value?.toLowerCase()) {
      case 'model at home':
        _llmModel = ModelAtHome(notifyListeners, context: context);
        _parameters = {};
        defaultParameters!.forEach(
          (key, value) {
            Type runTimeType = value.runtimeType;
            if ((runTimeType == List<double>) || (runTimeType == List<int>)) {
              parameters![key] = value[1];
            } else if (runTimeType == List<bool>) {
              parameters![key] = value.first;
            }
          },
        );
        prefs.setString('provider', value!);
        break;
      default:
        _llmModel = null;
    }
    _provider = value;
  }

  LLMModel({this.context}) {
    SharedPreferences.getInstance().then(
      (value) {
        prefs = value;
      },
    );
  }

  void loadSavedData() {
    provider = prefs.getString('provider') ?? 'Model at home';
  }

  // TODO maybe implement embeddings?
  String buildPrompt(ChatData chatData, String query) {
    String prompt = chatData.usePreprompt[0] ? chatData.prePrompt ?? '' : '';
    String chatContext = '';
    if (chatData.useChatConversationContext[0]) {
      for (var i = 0; i < chatData.messageList.length - 1; i++) {
        Message message = chatData.messageList[i];
        prompt += '${message.message} ';
        switch (message.role) {
          case MessageRole.user:
            chatContext += 'User: ${message.message}\n';
            break;
          case MessageRole.model:
            chatContext += 'Model: ${message.message}\n';
            break;
          default:
        }
      }
    }

    if (prompt.contains('{chatcontext}')) {
      prompt = prompt.replaceAll('{chatcontext}', chatContext);
    } else {
      prompt += chatContext;
    }

    if (prompt.contains('{query}')) {
      prompt = prompt.replaceAll('{query}', query);
    } else {
      prompt += query;
    }
    // print(query);
    return prompt;
  }

  Future<String?> generateText(BuildContext context, String prompt) async {
    return _llmModel!.generateText(prompt, parameters!).catchError((e) {
      Utils.showSnackBar(
        context,
        title: 'Master! Something Went Wrong:',
        subTitle: e.toString(),
      );
      return null;
    });
  }
}
