import "package:flutter/material.dart";

import '../models/chat_data.dart';
import '../models/llm_model.dart';
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

String getDay(String value) {
  DateTime dateTimeNow = DateTime.now().toUtc();
  // print(value.substring(0));
  final List<String> splittedValue = value.split('-');

  int yearOfValue = int.parse(splittedValue[0]);
  int todayYear = dateTimeNow.year;

  int monthOfValue = int.parse(splittedValue[1]);
  int todayMonth = dateTimeNow.month;

  int dateOfValue = int.parse(splittedValue[2]);
  int todayDate = dateTimeNow.day;

  if (dateOfValue == todayDate) {
    return 'Today';
  }
  int deltaDate = todayDate - dateOfValue;
  if (deltaDate == 1 &&
      monthOfValue == todayMonth &&
      yearOfValue == todayYear) {
    return 'Yesterday';
  }
  return value;
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
                  itemBuilder: (context, index) {
                    List<ChatData> dataList = widget.chatDataList.dataList;

                    return ChatListCardWidget(
                      isSelected: index == widget.chatDataList.currentSelected,
                      hoverColor: MyColors.bgTintBlue.withOpacity(0.5),
                      chatTitle: dataList[index].title,
                      chatSubtitle:
                          dataList[index].messageList.last.message == ''
                              ? dataList[index]
                                  .messageList[
                                      dataList[index].messageList.length - 2]
                                  .message
                              : dataList[index].messageList.last.message,
                      rightWidget: Text(getDay(dataList[index].dateCreated)),
                      onTap: () {
                        widget.chatDataList.loadData(index);
                        widget.chatDataList
                            .applyParameter(widget.llmModel.parameters!);
                      },
                    );
                  },
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
