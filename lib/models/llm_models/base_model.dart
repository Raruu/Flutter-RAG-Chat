import 'package:flutter/material.dart';

abstract class BaseModel {
  late Map<String, dynamic> defaultParameters;
  late Widget settingsWidget;
  late Widget informationWidget;
  late Function() notifyListener;
  BaseModel(this.notifyListener);

  Future<String?> generateText(String prompt, Map<String, dynamic> parameters);
}
