import 'package:flutter/material.dart';

abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  late Widget settingsWidget;
  late Widget informationWidget;
  late Function() notifyListener;
  Function()? onChatSettingsChanged;
  Function(List<dynamic> values)? setKnowledge;
  Function(dynamic value, {String? webFileName})? addKnowledge;
  BaseModel(this.notifyListener);

  Future<String?> generateText(String prompt, Map<String, dynamic> parameters);
}
