import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  late Widget widgetLlmodelSetting;
  late Widget widgetEmbeddingmodelSetting;
  late Widget informationWidget;

  Future? onChatSettingsChanged();
  Future? resetKnowledge();
  Future? deleteKnowledge(String filename);
  Future? setKnowledge(List<Map<String, dynamic>> knowledges);
  Future? addKnowledge(dynamic value, {String? webFileName});

  late Function() notifyListenerLLM;
  late SharedPreferences prefs;
  BaseModel(this.notifyListenerLLM, this.prefs);

  Future<Map<String, dynamic>?> generateText({
    required String prompt,
    required int seed,
    required Map<String, dynamic> parameters,
  });
}
