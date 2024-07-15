import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm_models/model_at_home.dart';
import 'llm_models/base_model.dart';
import '../utils/util.dart';

class LLMModel {
  late final SharedPreferences prefs;
  BaseModel? _llmModel;
  Map<String, dynamic>? get defaultParameters => _llmModel?.defaultParameters;

  Map<String, dynamic>? _parameters;
  Map<String, dynamic>? get parameters => _parameters;

  final List<String> providersList = [
    'OpenAI',
    // 'Google',
    // 'Text-Generation-Webui',
    'Model at home',
  ];

  String? _provider;
  String? get provider => _provider;
  set provider(String? value) {
    switch (value?.toLowerCase()) {
      case 'model at home':
        _llmModel = ModelAtHome();
        _parameters = {};
        defaultParameters!.forEach(
          (key, value) {
            Type runTimeType = value.runtimeType;
            if ((runTimeType == List<double>) || (runTimeType == List<int>)) {
              parameters![key] = value[1];
            } else if (runTimeType == List<bool>) {
              parameters![key] = value.first;
            }
          },
        );
        prefs.setString('provider', value!);
        break;
      default:
        _llmModel = null;
    }
    _provider = value;
  }

  late final TextEditingController urlTextEditingController;

  void finishUrlEditing() {
    prefs.setString('providerUrl', urlTextEditingController.text);
  }

  LLMModel() {
    urlTextEditingController = TextEditingController();
    SharedPreferences.getInstance().then(
      (value) {
        prefs = value;
        provider = prefs.getString('provider') ?? 'Model at home';
        urlTextEditingController.text = prefs.getString('providerUrl') ?? '';
      },
    );
  }

  Future<String?> generateText(BuildContext context, String prompt) async {
    return _llmModel!
        .generateText(urlTextEditingController.text, prompt, parameters!)
        .catchError((e) {
      Utils.showSnackBar(
        context,
        title: 'Master! Something Went Wrong:',
        subTitle: e.toString(),
      );
      return null;
    });
  }
}
