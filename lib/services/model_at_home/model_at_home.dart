import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/message.dart';
import '../base_model.dart';
import 'settings_widget.dart';
import 'data.dart';
import 'information_widget.dart';
import '../../controllers/chat_data_list.dart';

enum ModelType { llm, embedding }

class ModelAtHome extends BaseModel {
  static ModelAtHome? _instance;
  factory ModelAtHome(
    dynamic Function() notifyListenersLLM,
    SharedPreferences prefs,
    ChatDataList chatDataList, {
    BuildContext? context,
  }) {
    _instance ??= ModelAtHome._internal(
      notifyListenersLLM,
      prefs,
      chatDataList,
      context: context,
    );
    return _instance!;
  }

  Map<String, String> justHeader = const {
    'Content-Type': 'application/json; charset=UTF-8'
  };

  @override
  Map<String, dynamic> get defaultParameters => {
        "max_new_tokens": [0, 256, 4096],
        "temperature": [0.001, 1.0, 5.0],
        "top_k": [0, 50, 200],
        "top_p": [0.0, 1.0, 1.0],
        "min_p": [0.0, 0.05, 1.0],
        "typical_p": [0.0, 1.0, 1.0],
        "repetition_penalty": [0.0, 1.0, 1.5],
        "do_sample": [false],
      };

  late final Data _data;

  late final Widget _informationWidget;
  @override
  Widget get informationWidget => _informationWidget;

  ModelAtHome._internal(
      super.notifyListenerLLM, super.prefs, super.chatDataList,
      {BuildContext? context}) {
    _data = Data(super.notifyListenerLLM, super.prefs, context: context);

    _informationWidget = InformationWidget(
      data: _data,
    );
  }

  @override
  Widget get widgetLlmodelSetting => SettingsWidget(
        data: _data,
        intialURL: _data.baseURL,
        onSetURL: (value) => _data.baseURL = value,
        intialValue: '',
        valueLabel: 'AutoModelForCausalLM',
        onUnsetValue: () => unloadModel(ModelType.llm),
        onSetValue: (value) => loadModel(ModelType.llm, value),
        suggestionsCallback: (search) => _data.llmModelOnServer,
        availabValueRefresh: _data.getModelOnServer,
        modelName: _data.modelId,
      );

  @override
  Widget get widgetEmbeddingmodelSetting => SettingsWidget(
        data: _data,
        intialURL: _data.baseURL,
        onSetURL: (value) => _data.baseURL = value,
        intialValue: '',
        valueLabel: 'SentenceTransformer',
        onUnsetValue: () => unloadModel(ModelType.embedding),
        onSetValue: (value) => loadModel(ModelType.embedding, value),
        suggestionsCallback: (search) => _data.embeddingModelOnServer,
        availabValueRefresh: _data.getModelOnServer,
        modelName: _data.embeddingModelId,
      );

  void loadModel(ModelType modelType, String modelId) async {
    Uri uri = Uri.parse(
        '${_data.baseURL}/load_model/${modelType.name.toUpperCase()}?model_id=$modelId');
    var httpPost = http.post(uri);
    _data.startgetInformationPeriodic(tryCancle: true);
    _data.getInformation();
    await httpPost;
    _data.startgetInformationPeriodic(tryCancle: true);
    _data.getInformation();
    notifyListenerLLM();
  }

  void unloadModel(ModelType modelType) async {
    Uri uri = Uri.parse(
        '${_data.baseURL}/unload_model/${modelType.name.toUpperCase()}');
    await http.delete(uri);
    _data.startgetInformationPeriodic(tryCancle: true);
    _data.getInformation();
    notifyListenerLLM();
  }

  @override
  Future? resetKnowledge() async {
    Uri uri = Uri.parse('${_data.baseURL}/reset_chatroom_knowledge');
    http.Response response = await http.delete(uri);
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('[resetKnowledge]: ${response.body}');
      }
    }
  }

  @override
  Future<bool> deleteKnowledge(String filename) async {
    Uri uri = Uri.parse('${_data.baseURL}/delete_chatroom_knowledge');
    http.Response response = await http.delete(uri,
        headers: justHeader, body: jsonEncode({'filename': filename}));
    return response.body.toLowerCase().contains('true');
  }

  @override
  Future<void> setKnowledge(List<Map<String, dynamic>> knowledges) async {
    if (knowledges.isEmpty) {
      resetKnowledge();
      return;
    }
    try {
      Uri uri = Uri.parse('${_data.baseURL}/set_chatroom_knowledge');
      var request = http.MultipartRequest('POST', uri);
      for (var knowledge in knowledges) {
        if (kIsWeb) {
          request.files.add(
            http.MultipartFile.fromBytes('data', knowledge['web_data'],
                contentType: MediaType('application', 'pdf'),
                filename: knowledge['title']),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'data',
              knowledge['path'],
            ),
          );
        }
      }

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('[setKnowledge]: ${response.reasonPhrase}');
        }
      } else {
        throw (response.reasonPhrase ?? 'Fail');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> addKnowledge(dynamic value, {String? webFileName}) async {
    try {
      Uri uri = Uri.parse('${_data.baseURL}/add_context_knowledge');
      var request = http.MultipartRequest('POST', uri);
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes('data', value,
              contentType: MediaType('application', 'pdf'),
              filename: webFileName),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'data',
            value,
          ),
        );
      }

      http.StreamedResponse response = await request.send();
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('[addKnowledge]: ${response.reasonPhrase}');
          return true;
        }
      } else {
        throw ('[addKnowledge] ${response.reasonPhrase}');
        // return false;
      }
    } catch (e) {
      rethrow;
    }
    return false;
  }

  @override
  Future<bool>? onChatSettingsChanged({dynamic throwOnError}) async {
    try {
      Uri uri = Uri.parse('${_data.baseURL}/set_chatroom');

      http.Response response = await http.post(
        uri,
        headers: justHeader,
        body: jsonEncode({'id': chatDataList.currentData.id}),
      );
      return response.statusCode == 200;
    } catch (e) {
      if (throwOnError ?? false) {
        rethrow;
      }
      return false;
    }
  }

  Future<bool> checkServerChatRoomIsNotRoom() async {
    String url = '${_data.baseURL}/get_chatroom_id';
    Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      throw ('Invalid uri: $url');
    }
    http.Response response = await http.get(uri);
    if (response.statusCode == 200) {
      return response.body.replaceAll('"', '') != chatDataList.currentData.id;
    }
    return false;
  }

  @override
  Future<Map<String, dynamic>?> generateText({
    required String query,
    required int seed,
    required Map<String, dynamic> parameters,
    Map<String, dynamic>? retrievalContext,
  }) async {
    try {
      if (await checkServerChatRoomIsNotRoom()) {
        await onChatSettingsChanged(throwOnError: true);
      }
      String url = '${_data.baseURL}/generate_text';
      Uri uri = Uri.parse(url);

      List<dynamic> context1 =
          retrievalContext?['context1'] ?? List<String>.empty();
      List<String> context2 =
          chatDataList.currentData.useChatConversationContext[0]
              ? (retrievalContext?['context2'] ?? List<String>.empty())
                  .cast<String>()
              : List<String>.empty();

      String preprompt = chatDataList.currentData.usePreprompt[0]
          ? (chatDataList.currentData.prePrompt ?? "")
          : "";
      http.Response response = await http.post(
        uri,
        headers: justHeader,
        body: jsonEncode({
          "query": query,
          "preprompt": preprompt,
          "context1": context1,
          "context2": context2,
          "seed": seed,
          ...parameters,
        }),
      );

      if (response.statusCode == 200) {
        var responseJson = jsonDecode(response.body);
        return {
          'context1': responseJson['context1'],
          'context2': responseJson['context2'],
          'query': responseJson['query'],
          'seed': responseJson['seed'].toString(),
          'generated_text': formatOutputText(responseJson['generated_text']),
        };
      } else {
        throw (response.reasonPhrase ?? 'Fail');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> retrievalContext({
    required String query,
    required int seed,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      if (await checkServerChatRoomIsNotRoom()) {
        await onChatSettingsChanged(throwOnError: true);
      }
      String url = '${_data.baseURL}/retrieval_context';
      Uri uri = Uri.parse(url);

      List<String> chatHistory = List.empty(growable: true);
      for (var i = 0;
          i < chatDataList.currentData.messageList.length - 2;
          i++) {
        Message message = chatDataList.currentData.messageList[i];
        chatHistory.add(
            "${message.role == MessageRole.user ? "User" : "Model"}: ${message.message}");
      }

      http.Response response = await http.post(
        uri,
        headers: justHeader,
        body: jsonEncode({
          "query": query,
          "seed": seed,
          "context2": chatHistory,
          ...parameters,
        }),
      );

      if (response.statusCode == 200) {
        var responseJson = jsonDecode(response.body);
        return {
          'context1': responseJson['context1'],
          'context2': responseJson['context2'],
          'query': responseJson['query'],
          'seed': responseJson['seed'].toString(),
        };
      } else {
        throw (response.reasonPhrase ?? 'Fail');
      }
    } catch (e) {
      rethrow;
    }
  }

  String formatOutputText(String text) {
    if (text.isEmpty) {
      return text;
    }
    String formattedString = text.replaceAll('\\n', '\n');
    return formattedString;
  }
}
