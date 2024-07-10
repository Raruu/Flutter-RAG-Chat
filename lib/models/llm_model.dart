import 'package:flutter/material.dart';

import 'llm_models/model_at_home.dart';
import 'llm_models/base_model.dart';

class LLMModel {
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
        // defaultParameters = _llmModel!.defaultParameters;
        _parameters = {};
        defaultParameters!.forEach(
          (key, value) {
            Type runTimeType = value.runtimeType;
            if ((runTimeType == List<double>) || (runTimeType == List<int>)) {
              parameters![key] = value[1];
            } else if (runTimeType == List<bool>) {
              parameters![key] = value;
            }
          },
        );
        break;
      default:
        _llmModel = null;
    }
    _provider = value;
  }

  late final TextEditingController urlTextEditingController;

  LLMModel() {
    urlTextEditingController = TextEditingController();
    provider = 'Model at home';
  }

  Future<String?> generateText(String prompt) => _llmModel!
      .generateText(urlTextEditingController.text, prompt, parameters!);
}
