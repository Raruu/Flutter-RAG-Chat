import "package:flutter/material.dart";

import '../models/llm_model.dart';
import '../models/chat_data_list.dart';
import './home_page_desktop.dart';
import './home_page_mobile.dart';

class HomePage extends StatefulWidget {
  final ChatDataList chatDataList;
  final LLMModel llmModel;
  final int initialMenuSelected;
  final bool initialCtnRightOpen;
  const HomePage({
    super.key,
    required this.llmModel,
    required this.initialMenuSelected,
    required this.initialCtnRightOpen,
    required this.chatDataList,
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
    super.initState();
  }

  @override
  void dispose() {
    searchEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.shortestSide < 550) {
      return HomePageMobile(
        llmModel: widget.llmModel,
        chatDataList: widget.chatDataList,
        initialMenuSelected: widget.initialMenuSelected,
        searchEditingController: searchEditingController,
      );
    }
    return HomePageDesktop(
      llmModel: widget.llmModel,
      chatDataList: widget.chatDataList,
      initialCtnRightOpen: widget.initialCtnRightOpen,
      initialMenuSelected: widget.initialMenuSelected,
      searchEditingController: searchEditingController,
    );
  }
}
