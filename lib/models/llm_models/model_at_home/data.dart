import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/utils/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Data {
  Function() notifyListener;
  late final SharedPreferences prefs;
  String _baseURL = '';
  String get baseURL => _baseURL;
  set baseURL(String value) {
    _baseURL = value;
    prefs.setString('providerUrl', value);
    getModelOnServer();
    getInformation();
  }

  final List<String> _llmModelOnServer = [];
  List<String>? get llmModelOnServer =>
      _llmModelOnServer.isEmpty ? null : _llmModelOnServer;

  final List<String> _embeddingModelOnServer = [];
  List<String>? get embeddingModelOnServer =>
      _embeddingModelOnServer.isEmpty ? null : _embeddingModelOnServer;

  void getModelOnServer() async {
    _llmModelOnServer.clear();
    _embeddingModelOnServer.clear();
    Uri uri = Uri.parse('$baseURL/get_model_list');
    http.Response response = await http.get(uri);
    if (response.statusCode == 200) {
      Map<String, dynamic> responseJson = jsonDecode(response.body);
      for (String item in responseJson['LLM']) {
        _llmModelOnServer.add(item);
      }
      for (String item in responseJson['EMBEDDING']) {
        _embeddingModelOnServer.add(item);
      }
    }
  }

  String? gpuName;
  List<double>? ram;
  List<double>? vram;
  String? modelId;
  String? embeddingModelId;
  double? llmModelMemoryUsage;
  double? embeddingModelMemoryUsage;
  int? lenContextKnowledge;
  List<String>? listContextKnowledge;
  void setNull() {
    gpuName = null;
    ram = null;
    vram = null;
    modelId = null;
    llmModelMemoryUsage = null;
    getInformationPeriodic = null;
    notifyListener();
  }

  BuildContext? context;
  Data(this.notifyListener, this.prefs, {this.context}) {
    _baseURL = prefs.getString('providerUrl') ?? '';
    getInformation();
  }

  Timer? getInformationPeriodic;
  void startgetInformationPeriodic({bool tryCancle = false}) {
    if (tryCancle) {
      getInformationPeriodic?.cancel();
      getInformationPeriodic = null;
    }
    getInformationTryReconnect = false;
    getInformationPeriodic ??= Timer.periodic(
      const Duration(seconds: 3),
      (timer) => getInformation(),
    );
  }

  bool getInformationTryReconnect = true;
  void getInformation() async {
    try {
      Uri uri = Uri.parse('$baseURL/get_information');
      http.Response response = await http.get(uri);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseJson = jsonDecode(response.body);
        if (kDebugMode) {
          // print('GetInformation: $responseJson');
        }
        gpuName = responseJson['gpu_name'];
        ram = List<double>.from(responseJson['ram']);
        vram = List<double>.from(responseJson['vram']);
        modelId = responseJson['llmmodel_id'];
        embeddingModelId = responseJson['embedding_model_id'];
        llmModelMemoryUsage = responseJson['llmmodel_in_mem'];
        embeddingModelMemoryUsage = responseJson['embedding_model_in_mem'];
        lenContextKnowledge = responseJson['len_context_knowledge'];
        listContextKnowledge =
            List.from(responseJson['list_context_knowledge']);
        notifyListener();

        startgetInformationPeriodic();
      }
    } on SocketException catch (e) {
      if (getInformationTryReconnect) {
        getInformationPeriodic?.cancel();
        setNull();
        if (context != null && context!.mounted) {
          Utils.showSnackBar(context!,
              title: 'Get Information:',
              duration: const Duration(seconds: 5),
              subTitle: e.toString());
        }
        if (kDebugMode) {
          print('GetInformation Err: $e');
        }
        return;
      }
      if (context != null) {
        Utils.showSnackBar(context!,
            title: 'Get Information:',
            duration: const Duration(milliseconds: 600),
            subTitle: 'Reconnecting');
      }

      getInformationTryReconnect = true;
    } catch (e) {
      getInformationPeriodic?.cancel();
      if (context != null && context!.mounted) {
        Utils.showSnackBar(context!,
            title: 'Get Information:', subTitle: e.toString());
      }
      if (kDebugMode) {
        print('GetInformation Err: $e');
      }
    }
  }
}
