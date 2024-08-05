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
    getInformation();
  }

  String? gpuName;
  List<double>? ram;
  List<double>? vram;
  String? modelId;
  double? llmModelMemoryUsage;
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
        llmModelMemoryUsage = responseJson['llmmodel_in_mem'];
        lenContextKnowledge = responseJson['len_context_knowledge'];
        listContextKnowledge =
            List.from(responseJson['list_context_knowledge']);
        notifyListener();

        getInformationTryReconnect = false;
        getInformationPeriodic ??= Timer.periodic(
          const Duration(seconds: 3),
          (timer) => getInformation(),
        );
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
      Utils.showSnackBar(context!,
          title: 'Get Information:',
          duration: const Duration(milliseconds: 600),
          subTitle: 'Reconnecting');
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
