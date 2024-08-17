import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  late Widget settingLlmodelWidget;
  late Widget settingEmbeddingModelWidget;
  late Widget informationWidget;
  Function()? onChatSettingsChanged;
  Function()? resetKnowledge;
  Function(String filename)? deleteKnowledge;
  Function(List<Map<String, dynamic>> knowledges)? setKnowledge;
  Function(dynamic value, {String? webFileName})? addKnowledge;

  late Function() notifyListener;
  late SharedPreferences prefs;
  BaseModel(this.notifyListener, this.prefs);

  Future<Map<String, dynamic>?> generateText(
      String prompt, Map<String, dynamic> parameters);
}
