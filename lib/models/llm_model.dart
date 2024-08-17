import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_rag_chat/models/chat_data.dart';
import 'package:flutter_rag_chat/models/chat_data_list.dart';
import 'package:flutter_rag_chat/models/message.dart';
import 'llm_models/model_at_home.dart';
import 'llm_models/base_model.dart';
import '../utils/util.dart';
import './llm_models/default_preprompt.dart' as df_preprompt;

class LLMModel extends ChangeNotifier {
  final ChatDataList chatDataList;
  BuildContext? context;
  late final SharedPreferences prefs;

  BaseModel? _llmModel;
  Function()? get onChatSettingsChanged {
    chatDataList.updateConfigToDatabase();
    return _llmModel?.onChatSettingsChanged;
  }

  Function()? get resetKnowledge => _llmModel?.resetKnowledge;
  Function(String filename)? get deleteKnowledge => _llmModel?.deleteKnowledge;
  Function(List<Map<String, dynamic>> knowledges)? get setKnowledge {
    return _llmModel?.setKnowledge;
  }

  Function(dynamic value, {String? webFileName})? get addKnowledge =>
      _llmModel?.addKnowledge;
  Map<String, dynamic>? get defaultParameters => _llmModel?.defaultParameters;
  String get defaultPrePrompt => df_preprompt.defaultPrePrompt;

  Widget get settingLlmodelWidget =>
      _llmModel?.settingLlmodelWidget ?? const LinearProgressIndicator();
  Widget get settingEmbeddingModelWidget =>
      _embeddingModel?.settingEmbeddingModelWidget ??
      const LinearProgressIndicator();
  Widget get informationWidget =>
      _llmModel?.informationWidget ?? const SizedBox();

  Map<String, dynamic>? _parameters;
  Map<String, dynamic>? get parameters => _parameters;

  final List<String> llmProvidersList = const [
    'OpenAI',
    // 'Google',
    // 'Text-Generation-Webui',
    'Model at home',
  ];

  String? _llmProvider;
  String? get llmProvider => _llmProvider;
  set llmProvider(String? value) {
    switch (value?.toLowerCase()) {
      case 'model at home':
        _llmModel = ModelAtHome(
          notifyListeners,
          prefs,
          context: context,
          chatDataList: chatDataList,
        );
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
        prefs.setString('llm_provider', value!);
        break;
      default:
        _llmModel = null;
    }
    _llmProvider = value;
  }

  BaseModel? _embeddingModel;
  final List<String> embeddingProvidersList = const [
    'OpenAI',
    'Model at home',
  ];
  String? _embeddingProvider;
  String? get embeddingProvider => _embeddingProvider;
  set embeddingProvider(String? value) {
    switch (value?.toLowerCase()) {
      case 'model at home':
        _embeddingModel = ModelAtHome(
          notifyListeners,
          prefs,
          context: context,
          chatDataList: chatDataList,
        );
        prefs.setString('embedding_provider', value!);
        break;
      default:
        _embeddingModel = null;
    }
    _embeddingProvider = value;
  }

  LLMModel(this.chatDataList, {this.context, required this.prefs});

  void loadSavedData() {
    llmProvider = prefs.getString('llm_provider') ?? 'Model at home';
    embeddingProvider =
        prefs.getString('embedding_provider') ?? 'Model at home';
  }

  // TODO ?
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

  Future<Map<String, dynamic>?> generateText(
      BuildContext context, String prompt) {
    return _llmModel!.generateText(prompt, parameters!).catchError((e) {
      if (kDebugMode) {
        print(e);
      }
      if (context.mounted) {
        Utils.showSnackBar(
          context,
          title: '[GenerateText] Master! Something Went Wrong:',
          subTitle: e.toString(),
        );
      }
      return null;
    });
  }
}
