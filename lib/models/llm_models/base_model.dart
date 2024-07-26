import 'dart:io';

import 'package:flutter/material.dart';

abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  late Widget settingsWidget;
  late Widget informationWidget;
  late Function() notifyListener;
  Function()? onChatSettingsChanged;
  Function(List<File>)? setKnowledge;
  Function(File file)? addKnowledge;
  BaseModel(this.notifyListener);

  Future<String?> generateText(String prompt, Map<String, dynamic> parameters);
}
