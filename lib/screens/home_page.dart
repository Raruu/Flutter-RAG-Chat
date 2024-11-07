import "package:flutter/material.dart";

import '../services/llm_model.dart';
import '../controllers/chat_data_list.dart';
import './home_page_desktop.dart';
import './home_page_mobile.dart';
import '../utils/util.dart';

class HomePage extends StatefulWidget {
  final ChatDataList chatDataList;
  final LLMModel llmModel;
  final int initialMenuSelected;
  final bool initialCtnRightOpen;
  final String initialChatId;
  final Function() toggleDarkMode;
  const HomePage({
    super.key,
    required this.llmModel,
    required this.initialMenuSelected,
    required this.initialCtnRightOpen,
    required this.chatDataList,
    required this.initialChatId,
    required this.toggleDarkMode,
  });
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final TextEditingController searchEditingController;

  @override
  void initState() {
    searchEditingController = TextEditingController();
    widget.llmModel.context ??= context;
    widget.llmModel.loadSavedData();
    if (widget.initialChatId.length > 2) {
      for (var i = 0; i < widget.chatDataList.dataList.length; i++) {
        var data = widget.chatDataList.dataList[i];
        if (data.id == widget.initialChatId) {
          widget.chatDataList.loadData(i);
          break;
        }
      }
    }
    super.initState();
  }

  @override
  void dispose() {
    searchEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Utils.isMobileSize(context)) {
      return HomePageMobile(
        llmModel: widget.llmModel,
        chatDataList: widget.chatDataList,
        initialMenuSelected: widget.initialMenuSelected,
        searchEditingController: searchEditingController,
        toggleDarkMode: widget.toggleDarkMode,
      );
    }
    return HomePageDesktop(
      llmModel: widget.llmModel,
      chatDataList: widget.chatDataList,
      initialCtnRightOpen: widget.initialCtnRightOpen,
      initialMenuSelected: widget.initialMenuSelected,
      searchEditingController: searchEditingController,
      toggleDarkMode: widget.toggleDarkMode,
    );
  }
}
