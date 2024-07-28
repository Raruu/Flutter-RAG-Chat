import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_rag_chat/models/message.dart';
import 'base_model.dart';
import './model_at_home/settings_widget.dart';
import './model_at_home/data.dart';
import './model_at_home/information_widget.dart';
import '../chat_data_list.dart';

class ModelAtHome<T> extends BaseModel {
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

  final ChatDataList chatDataList;
  late final Data _data;
  late final Widget _settingsWidget;
  @override
  Widget get settingsWidget => _settingsWidget;

  late final Widget _informationWidget;
  @override
  Widget get informationWidget => _informationWidget;

  ModelAtHome(super.notifyListeners,
      {BuildContext? context, required this.chatDataList}) {
    _data = Data(super.notifyListener, context: context);
    _settingsWidget = SettingsWidget(
      data: _data,
    );
    _informationWidget = InformationWidget(
      data: _data,
    );
  }

  @override
  Function()? get resetKnowledge => _resetKnowledge;
  void _resetKnowledge() async {
    Uri uri = Uri.parse('${_data.baseURL}/reset_chatroom_knowledge');
    http.Response response = await http.delete(uri);
    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('[resetKnowledge]: ${response.body}');
      }
    }
  }

  @override
  Function(String filename)? get deleteKnowledge => _deleteKnowledge;
  Future<bool> _deleteKnowledge(String filename) async {
    Uri uri = Uri.parse('${_data.baseURL}/delete_chatroom_knowledge');
    http.Response response = await http.delete(uri,
        headers: justHeader, body: jsonEncode({'filename': filename}));
    return response.body.toLowerCase().contains('true');
  }

  @override
  Function(List<Map<String, dynamic>>)? get setKnowledge => _setKnowledge;
  void _setKnowledge(List<Map<String, dynamic>> knowledges) async {
    if (knowledges.isEmpty) {
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
          print('[setKnowledge]: ${response.toString()}');
        }
      } else {
        throw ('[setKnowledge] ${response.reasonPhrase}');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> Function(dynamic value, {String? webFileName})
      get addKnowledge => _addKnowledge;
  Future<bool> _addKnowledge(dynamic value, {String? webFileName}) async {
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
          print('[addKnowledge]: ${response.toString()}');
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
  Function()? get onChatSettingsChanged => setServerChatRoom;
  Future<bool> setServerChatRoom({bool? throwOnError}) async {
    try {
      Uri uri = Uri.parse('${_data.baseURL}/set_chatroom');
      var currentData = chatDataList.currentData;
      List<String> chatHistory = [];
      for (var i = 0; i < currentData.messageList.length - 2; i++) {
        var message = currentData.messageList[i];
        switch (message.role) {
          case MessageRole.user:
            chatHistory.add('User: ${message.message}\n');
            break;
          case MessageRole.model:
            chatHistory.add('Model: ${message.message}\n');
            break;
          default:
        }
      }
      http.Response response = await http.post(
        uri,
        headers: justHeader,
        body: jsonEncode({
          'id': chatDataList.currentData.id,
          'use_preprompt': currentData.usePreprompt[0],
          'preprompt': currentData.usePreprompt[0] ? currentData.prePrompt : '',
          'use_chat_history': currentData.useChatConversationContext[0],
          'chat_history':
              currentData.useChatConversationContext[0] ? chatHistory : []
        }),
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
  Future<Map<String, dynamic>?> generateText(
    String prompt,
    Map<String, dynamic> parameters,
  ) async {
    try {
      if (await checkServerChatRoomIsNotRoom()) {
        await setServerChatRoom(throwOnError: true);
      }
      String url = '${_data.baseURL}/generate_text';
      Uri uri = Uri.parse(url);

      if (kDebugMode) {
        print('JsonEncode: ${jsonEncode({"query": prompt, ...parameters})}');
      }

      http.Response response = await http.post(
        uri,
        headers: justHeader,
        body: jsonEncode({
          "query": prompt,
          ...parameters,
        }),
      );

      if (response.statusCode == 200) {
        var responseJson = jsonDecode(response.body);
        return {
          'context1': responseJson['context1'],
          'context2': responseJson['context2'],
          'query': responseJson['query'],
          'generated_text': formatOutputText(responseJson['generated_text']),
        };
      } else {
        throw (response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  String formatOutputText(String text) {
    String formattedString =
        text.substring(1, text.length - 1).replaceAll('\\n', '\n');
    return formattedString;
  }
}
