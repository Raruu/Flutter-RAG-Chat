import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/models/chat_data.dart';
import 'package:flutter_rag_chat/models/message.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm_models/model_at_home.dart';
import 'llm_models/base_model.dart';
import '../utils/util.dart';
import './llm_models/default_preprompt.dart' as df_preprompt;

class LLMModel {
  late final SharedPreferences prefs;
  BaseModel? _llmModel;
  Map<String, dynamic>? get defaultParameters => _llmModel?.defaultParameters;
  String get defaultPrePrompt => df_preprompt.defaultPrePrompt;

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
        _llmModel = ModelAtHome();
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

  late final TextEditingController urlTextEditingController;

  void finishUrlEditing() {
    prefs.setString('providerUrl', urlTextEditingController.text);
  }

  LLMModel() {
    urlTextEditingController = TextEditingController();
    SharedPreferences.getInstance().then(
      (value) {
        prefs = value;
        provider = prefs.getString('provider') ?? 'Model at home';
        urlTextEditingController.text = prefs.getString('providerUrl') ?? '';
      },
    );
  }

  // TODO
  String buildPrompt(ChatData chatData, String newUserInput) {
    String prompt = '';
    if (chatData.usePreprompt[0]) {
      prompt += chatData.prePrompt ?? '';
    }
    if (chatData.useChatConversationContext[0]) {
      for (var i = 0; i < chatData.messageList.length - 1; i++) {
        Message message = chatData.messageList[i];
        prompt += '${message.message} ';
        // switch (message.role) {
        //   case MessageRole.user:
        //     prompt += 'User: ${message.message} ';
        //     break;
        //   case MessageRole.model:
        //     prompt += 'Model: ${message.message} ';
        //     break;
        //   default:
        // }
      }
    }
    prompt += newUserInput;
    print(prompt);
    return prompt;
  }

  Future<String?> generateText(BuildContext context, String prompt) async {
    return _llmModel!
        .generateText(urlTextEditingController.text, prompt, parameters!)
        .catchError((e) {
      Utils.showSnackBar(
        context,
        title: 'Master! Something Went Wrong:',
        subTitle: e.toString(),
      );
      return null;
    });
  }
}
