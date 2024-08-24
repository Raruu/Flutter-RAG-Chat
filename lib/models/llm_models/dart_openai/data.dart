import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Data {
  final SharedPreferences prefs;
  final Function() notifyListenerLLM;
  Data(this.prefs, this.notifyListenerLLM) {
    baseURL = prefs.getString('openai_baseurl') ?? '';
    apiKey = prefs.getString('openai_api') ?? '';
  }

  String _baseURL = '';
  String get baseURL => _baseURL;
  set baseURL(String value) {
    OpenAI.baseUrl = value == '' ? 'https://api.openai.com' : value;
    _baseURL = OpenAI.baseUrl;
    prefs.setString('openai_baseurl', value);
  }

  String _apiKey = '';
  String get apiKey => _apiKey;
  set apiKey(String value) {
    prefs.setString('openai_api', value);
    OpenAI.apiKey = value;
    _apiKey = value;
    getModelList();
  }

  String? _llmModel;
  String? get llmModel => _llmModel;
  set llmModel(String? value) {
    prefs.setString('openai_llmmodel', value ?? '');
    _llmModel = value;
  }

  List<OpenAIModelModel>? models;
  void getModelList() async {
    models = await OpenAI.instance.model.list();
    notifyListenerLLM();
    if (kDebugMode) {
      // print('Model List: $models');
    }
  }
}
