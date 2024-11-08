import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ragchat/models/message_context.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/chat_data_list.dart';
import '../models/message.dart';
import 'dart_openai/dart_openai.dart';
import 'model_at_home/model_at_home.dart';
import 'base_model.dart';
import '../utils/util.dart';
import 'default_preprompt.dart' as df_preprompt;
import 'gemini/google_gemini.dart';

class LLMModel extends ChangeNotifier {
  final ChatDataList _chatDataList;
  BuildContext? context;
  late final SharedPreferences prefs;
  BaseModel? _llmModel;

  Future? chatSettingsChanged() {
    _chatDataList.updateConfigToDatabase();
    return _llmModel?.onChatSettingsChanged()?.catchError(
        (e) => printcatchError(e: e, from: 'onChatSettingsChanged'));
  }

  Future? resetKnowledge() => _embeddingModel
      ?.resetKnowledge()
      ?.catchError((e) => printcatchError(e: e, from: 'resetKnowledge'));

  Future? deleteKnowledge(String filename) => _embeddingModel
      ?.deleteKnowledge(filename)
      ?.catchError((e) => printcatchError(e: e, from: 'DeleteKnowledge'));

  Future? setKnowledge(List<Map<String, dynamic>> knowledges) => _embeddingModel
      ?.setKnowledge(knowledges)
      ?.catchError((e) => printcatchError(e: e, from: 'setKnowledge'));

  Future? addKnowledge(dynamic value, {String? webFileName}) => _embeddingModel
      ?.addKnowledge(value, webFileName: webFileName)
      ?.catchError((e) => printcatchError(e: e, from: 'addKnowledge'));

  Map<String, dynamic>? get defaultParameters => _llmModel?.defaultParameters;
  String get defaultPrePrompt => df_preprompt.defaultPrePrompt;

  Widget get widgetLlmodelSetting =>
      _llmModel?.widgetLlmodelSetting ?? const LinearProgressIndicator();
  Widget get widgetEmbeddingmodelSetting =>
      _embeddingModel?.widgetEmbeddingmodelSetting ??
      const LinearProgressIndicator();
  Widget get informationWidget => _llmModel == _embeddingModel
      ? _llmModel?.informationWidget ?? const SizedBox()
      : Row(
          children: [
            _llmModel?.informationWidget ?? const SizedBox(),
            _embeddingModel?.informationWidget ?? const SizedBox()
          ],
        );

  Map<String, dynamic>? _parameters;
  Map<String, dynamic>? get parameters => _parameters;

  final List<String> llmProvidersList = const [
    'OpenAI',
    'Gemini',
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
          _chatDataList,
          context: context,
        );
        break;
      case 'openai':
        _llmModel = DartOpenai(notifyListeners, prefs, _chatDataList);
        break;
      case 'gemini':
        _llmModel = GoogleGemini(notifyListeners, prefs, _chatDataList);
        break;
      default:
        _llmModel = null;
    }
    _parameters = Utils.loadParametersWithDefaultParameters(defaultParameters);
    prefs.setString('llm_provider', value!);
    _llmProvider = value;
  }

  BaseModel? _embeddingModel;
  final List<String> embeddingProvidersList = const [
    'None',
    'Model at home',
  ];
  String? _embeddingProvider;
  String? get embeddingProvider => _embeddingProvider;
  set embeddingProvider(String? value) {
    switch (value?.toLowerCase()) {
      case 'none':
        _embeddingModel = null;
        prefs.setString('embedding_provider', value!);
        break;
      case 'model at home':
        _embeddingModel = ModelAtHome(
          notifyListeners,
          prefs,
          _chatDataList,
          context: context,
        );
        prefs.setString('embedding_provider', value!);
        break;
      default:
        _embeddingModel = null;
    }
    _embeddingProvider = value;
  }

  LLMModel(this._chatDataList, {this.context, required this.prefs});

  void loadSavedData() {
    llmProvider = prefs.getString('llm_provider') ?? 'Model at home';
    embeddingProvider =
        prefs.getString('embedding_provider') ?? 'Model at home';
  }

  Future<Map<String, dynamic>?> retrievalContext(
      {required String prompt, required int seed}) async {
    if (_embeddingModel == null) {
      return null;
    }
    return _embeddingModel!
        .retrievalContext(query: prompt, seed: seed, parameters: parameters!)
        .catchError((e) {
      printcatchError(e: e, from: 'retrievalContext');
      return null;
    });
  }

  Future<Message?> generateText(
      {required String query, required int seed}) async {
    Map<String, dynamic>? retrieval = await retrievalContext(
      prompt: query,
      seed: seed,
    );
    if (retrieval != null && retrieval['context1'] != "") {
      List<dynamic>? context1 = retrieval['context1']
          .take(_chatDataList.currentData.maxKnowledgeCount[0])
          .toList();
      retrieval['context1'] = List.empty(growable: true);

      for (var context1Data in context1!) {
        if (context1Data['score'] >=
            _chatDataList.currentData.minKnowledgeScore[0]) {
          retrieval['context1'].add(context1Data);
        }
      }
    }

    Map<String, dynamic>? generateOutput = await _llmModel!
        .generateText(
            query: query,
            seed: seed,
            parameters: parameters!,
            retrievalContext: retrieval)
        .catchError((e) => printcatchError(e: e, from: 'GenerateText'));

    if (generateOutput == null) {
      return null;
    }

    List<dynamic>? context1 =
        generateOutput['context1'] == "" ? null : generateOutput['context1'];

    return Message(
      role: MessageRole.model,
      message: generateOutput['generated_text'],
      token: Utils.calcToken(generateOutput['generated_text'].length),
      messageContext: MessageContext(
        query: generateOutput['query'],
        seed: int.tryParse(generateOutput['seed']) ?? 0,
        contextList: context1 == null
            ? List.empty()
            : List.generate(
                context1.length,
                (index) => MessageContextData(
                  contextText: context1[index]['context'],
                  filename: context1[index]['filename'],
                  pageNumber: context1[index]['page_number'],
                  score: context1[index]['score'],
                ),
              ),
      ),
    );
  }

  dynamic printcatchError({required dynamic e, required String from}) {
    if (kDebugMode) {
      print('[$from]: $e');
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
