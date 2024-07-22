import 'package:flutter/material.dart';

abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  late Widget settingsWidget;
  late Widget informationWidget;
  late Function() notifyListener;
  Function()? onChatSettingsChanged;
  BaseModel(this.notifyListener);

  Future<String?> generateText(String prompt, Map<String, dynamic> parameters);
}
