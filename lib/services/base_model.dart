import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/chat_data_list.dart';

abstract class BaseModel {
  Map<String, dynamic>? defaultParameters;
  Widget? widgetLlmodelSetting;
  Widget? widgetEmbeddingmodelSetting;
  Widget? informationWidget;

  Future? onChatSettingsChanged() => null;

  final Function() notifyListenerLLM;
  final SharedPreferences prefs;
  final ChatDataList chatDataList;
  BaseModel(this.notifyListenerLLM, this.prefs, this.chatDataList);

  Future<Map<String, dynamic>?> generateText({
    required String query,
    required int seed,
    required Map<String, dynamic> parameters,
    Map<String, dynamic>? retrievalContext,
  });

  Future? resetKnowledge() => null;
  Future? deleteKnowledge(String filename) => null;
  Future? setKnowledge(List<Map<String, dynamic>> knowledges) => null;
  Future? addKnowledge(dynamic value, {String? webFileName}) => null;

  Future<Map<String, dynamic>?> retrievalContext({
    required String query,
    required int seed,
    required Map<String, dynamic> parameters,
  }) {
    throw UnimplementedError();
  }
}
