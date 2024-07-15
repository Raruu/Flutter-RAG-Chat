import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'base_model.dart';

class ModelAtHome extends BaseModel {
  @override
  Map<String, dynamic> get defaultParameters => {
        "max_new_tokens": [0, 256, 4096],
        "temperature": [0.001, 1.0, 5.0],
        "top_k": [0, 50, 200],
        "top_p": [0.0, 1.0, 1.0],
        "min_p": [0.0, 0.05, 1.0],
        "typical_p": [0.0, 1.0, 1.0],
        "repetition_penalty": [0.0, 1.0, 1.5],
        "do_sample": [false],
      };

  // @override
  // set parameters(value){}

  // ModelAtHome() {}

  @override
  Future<String?> generateText(
    String url,
    String prompt,
    Map<String, dynamic> parameters,
  ) async {
    try {
      url += '/generate_text';
      Uri? uri = Uri.tryParse(url);
      if (uri == null) {
        throw ('Invalid uri: $url');
      }
      if (kDebugMode) {
        print('JsonEncode: ${jsonEncode({"prompt": prompt, ...parameters})}');
      }

      http.Response response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          "prompt": prompt,
          ...parameters,
        }),
      );

      if (response.statusCode == 200) {
        return formatOutputText(response.body);
      } else {
        throw (response.statusCode);
      }
    } catch (e) {
      rethrow;
    }
  }

  String formatOutputText(String text) {
    String formattedString =
        text.substring(1, text.length - 1).replaceAll('\\n', '\n');
    return formattedString;
  }
}
