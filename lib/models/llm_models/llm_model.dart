import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_rag_chat/models/chat_data.dart';
import 'package:flutter_rag_chat/models/chat_data_list.dart';
import 'package:flutter_rag_chat/models/message.dart';
import 'model_at_home/model_at_home.dart';
import 'base_model.dart';
import '../../utils/util.dart';
import 'default_preprompt.dart' as df_preprompt;

class LLMModel extends ChangeNotifier {
  final ChatDataList chatDataList;
  BuildContext? context;
  late final SharedPreferences prefs;
  BaseModel? _llmModel;

  Future? onChatSettingsChanged() {
    chatDataList.updateConfigToDatabase();
    return _llmModel?.onChatSettingsChanged()?.catchError(
        (e) => printcatchError(e: e, from: 'onChatSettingsChanged'));
  }

  Future? resetKnowledge() => _llmModel
      ?.resetKnowledge()
      ?.catchError((e) => printcatchError(e: e, from: 'resetKnowledge'));

  Future? deleteKnowledge(String filename) => _llmModel
      ?.deleteKnowledge(filename)
      ?.catchError((e) => printcatchError(e: e, from: 'DeleteKnowledge'));

  Future? setKnowledge(List<Map<String, dynamic>> knowledges) => _llmModel
      ?.setKnowledge(knowledges)
      ?.catchError((e) => printcatchError(e: e, from: 'setKnowledge'));

  Future? addKnowledge(dynamic value, {String? webFileName}) => _llmModel
      ?.addKnowledge(value, webFileName: webFileName)
      ?.catchError((e) => printcatchError(e: e, from: 'addKnowledge'));

  Map<String, dynamic>? get defaultParameters => _llmModel?.defaultParameters;
  String get defaultPrePrompt => df_preprompt.defaultPrePrompt;

  Widget get widgetLlmodelSetting =>
      _llmModel?.widgetLlmodelSetting ?? const LinearProgressIndicator();
  Widget get widgetEmbeddingmodelSetting =>
      _embeddingModel?.widgetEmbeddingmodelSetting ??
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

  // TODO Save for later ?
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
    return prompt;
  }

  Future<Map<String, dynamic>?> generateText(
          {required String prompt, required int seed}) =>
      _llmModel!
          .generateText(prompt: prompt, seed: seed, parameters: parameters!)
          .catchError((e) {
        printcatchError(e: e, from: 'GenerateText');
        return null;
      });

  dynamic printcatchError({required dynamic e, required String from}) {
    if (kDebugMode) {
      print('[$from]: ${e.toString()}');
    }
    if (context != null && context!.mounted) {
      Utils.showSnackBar(
        context!,
        title: '[$from] Master! Something Went Wrong:',
        subTitle: e.toString(),
      );
    }
    return null;
  }
}
