import "package:flutter/material.dart";
import 'package:flutter_rag_chat/models/llm_model.dart';

import 'chat_list/chat_list_card_widget.dart';
import 'nice_button.dart';
import 'pink_textfield.dart';
import '../utils/svg_icons.dart';
import '../utils/my_colors.dart';
import '../models/chat_data_list.dart';

class ChatList extends StatefulWidget {
  final TextEditingController searchEditingController;
  final ChatDataList chatDataList;
  final Function() newChatFunction;
  final LLMModel llmModel;
  const ChatList({
    super.key,
    required this.searchEditingController,
    required this.chatDataList,
    required this.newChatFunction,
    required this.llmModel,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PinkTextField(
          strIconLeft: SvgIcons.search,
          hintText: 'Search',
          textEditingController: widget.searchEditingController,
          leftButtonFunc: () {},
          onChanged: (value) {},
        ),
        const Padding(padding: EdgeInsets.all(8.0)),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.chatDataList.dataList.length,
                  itemBuilder: (context, index) => ChatListCardWidget(
                    isSelected: index == widget.chatDataList.currentSelected,
                    hoverColor: MyColors.bgTintBlue.withOpacity(0.5),
                    onTap: () {
                      widget.chatDataList.loadData(index);
                      widget.chatDataList
                          .applyParameter(widget.llmModel.parameters!);
                      // print(widget.llmModel.parameters);
                    },
                    chatTitle: widget.chatDataList.dataList[index].title,
                    rightWidget:
                        Text(widget.chatDataList.dataList[index].dateCreated),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(16.0)),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "That's All",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      ". . .",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        NiceButton(
          onTap: widget.newChatFunction,
          text: 'New Chat',
          backgroundColor: MyColors.bgTintBlue,
          strIcon: SvgIcons.plus,
          iconSize: 24,
          borderRadiusCircular: 32,
        )
      ],
    );
  }
}
