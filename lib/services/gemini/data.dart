import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class Data {
  final SharedPreferences _prefs;
  Data(this._prefs) {
    apiKey = _prefs.getString('gemini_api') ?? "";
  }

  List<GeminiModel>? geminiModels;

  String _apiKey = '';
  String get apiKey => _apiKey;
  set apiKey(String value) {
    _prefs.setString('gemini_api', value);
    Gemini.reInitialize(apiKey: value);
    Gemini.instance.listModels().then((value) {
      return geminiModels = value;
    });
    _apiKey = value;
  }
}
