import "package:flutter/material.dart";
import 'package:flutter_rag_chat/utils/util.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../models/chat_data.dart';
import '../../services/llm_model.dart';
import 'chat_list_card_widget.dart';
import '../nice_button.dart';
import '../pink_textfield.dart';
import '../../utils/svg_icons.dart';
import '../../utils/my_colors.dart';
import '../../models/chat_data_list.dart';

class ChatList extends StatefulWidget {
  final TextEditingController searchEditingController;
  final ChatDataList chatDataList;
  final Function()? newChatFunction;
  final LLMModel llmModel;
  final bool mobileUI;
  final Function()? loadedDataCallback;
  const ChatList({
    super.key,
    required this.searchEditingController,
    required this.chatDataList,
    this.newChatFunction,
    required this.llmModel,
    this.mobileUI = false,
    this.loadedDataCallback,
  });

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
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

  void loadChat(
    int index,
  ) {
    widget.chatDataList
        .loadData(index, llmModel: widget.llmModel, context: context);
    widget.loadedDataCallback?.call();
  }

  late final FocusNode focusSearchTextField;
  int idxExpandedCardWidget = -1;
  bool isShowSearch = false;

  @override
  void initState() {
    focusSearchTextField = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    focusSearchTextField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.mobileUI)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    double width = constraints.maxWidth;
                    return Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.decelerate,
                          width: isShowSearch ? width : 0,
                          child: searchTextField(),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: AnimatedOpacity(
                              opacity: isShowSearch ? 0 : 1,
                              duration: const Duration(milliseconds: 200),
                              child: const Text(
                                'Chat',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900, fontSize: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  isShowSearch = !isShowSearch;
                  if (isShowSearch) {
                    focusSearchTextField.requestFocus();
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                }),
                icon: SvgPicture.string(
                  isShowSearch ? SvgIcons.miClose : SvgIcons.search,
                  width: 26,
                  height: 26,
                  colorFilter: ColorFilter.mode(
                    Utils.getDefaultTextColor(context)!,
                    BlendMode.srcIn,
                  ),
                ),
              )
            ],
          ),
        if (!widget.mobileUI) searchTextField(),
        if (widget.searchEditingController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Searched '${widget.searchEditingController.text}'",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
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
                    String searchedTitle = widget.searchEditingController.text;
                    if (searchedTitle != '' &&
                        !dataList[index]
                            .title
                            .toLowerCase()
                            .contains(searchedTitle.toLowerCase())) {
                      return const SizedBox();
                    }

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
                      rightWidget: Text(
                        getDay(dataList[index].dateCreated),
                        style: index == widget.chatDataList.currentSelected
                            ? const TextStyle(color: MyColors.textTintBlue)
                            : null,
                      ),
                      isShowExpandedChild: idxExpandedCardWidget == index,
                      expandedChild: expandedChild(index, context),
                      rightWidgetOnHover: IconButton(
                          onPressed: () => setState(() {
                                if (idxExpandedCardWidget == index) {
                                  idxExpandedCardWidget = -1;
                                  return;
                                }
                                idxExpandedCardWidget = index;
                              }),
                          icon: Icon(Icons.more_horiz_rounded,
                              color:
                                  index == widget.chatDataList.currentSelected
                                      ? MyColors.textTintBlue
                                      : Utils.getDefaultTextColor(context))),
                      onTap: () => loadChat(index),
                      onLongPress: () => setState(() {
                        if (idxExpandedCardWidget == index) {
                          idxExpandedCardWidget = -1;
                          return;
                        }
                        idxExpandedCardWidget = index;
                      }),
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
        if (!widget.mobileUI)
          NiceButton(
            onTap: () {
              widget.newChatFunction?.call();
              idxExpandedCardWidget = -1;
            },
            text: 'New Chat',
            backgroundColor: MyColors.bgTintBlue,
            strIcon: SvgIcons.plus,
            iconSize: 24,
            borderRadiusCircular: 32,
          )
      ],
    );
  }

  Padding expandedChild(int index, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 71),
      child: Container(
        margin: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      tooltip: 'Rename',
                      onPressed: () async {
                        TextEditingController textEditingController =
                            TextEditingController()
                              ..text =
                                  widget.chatDataList.dataList[index].title;
                        bool result = await Utils.showDialogYesNo(
                          context: context,
                          title: Container(
                            constraints: BoxConstraints(
                                minWidth:
                                    MediaQuery.sizeOf(context).width * 1 / 4),
                            child: const Text(
                              'Rename',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          content: PinkTextField(
                            textEditingController: textEditingController,
                            hintText: '',
                            labelText: 'CHAT TITLE',
                            backgroundColor: MyColors.bgTintBlue,
                          ),
                        );
                        if (result) {
                          widget.chatDataList.dataList[index].title =
                              textEditingController.text;
                          widget.chatDataList
                              .renameChat(textEditingController.text);
                        }
                        textEditingController.dispose();
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: MyColors.textTintBlue,
                      )),
                  const Text('Rename',
                      style: TextStyle(
                        color: MyColors.textTintBlue,
                      ))
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      tooltip: 'Delete',
                      onPressed: () async {
                        ChatData chatData = widget.chatDataList.dataList[index];
                        if (await Utils.showDialogYesNo(
                            context: context,
                            title: const Text('Delete Chat?'),
                            content: Text("'${chatData.title}'"))) {
                          widget.chatDataList.remove(chatData);
                          setState(() {
                            idxExpandedCardWidget = -1;
                          });
                        }
                      },
                      icon: const Icon(
                        Icons.delete,
                        color: MyColors.textTintBlue,
                      )),
                  const Text('Delete',
                      style: TextStyle(
                        color: MyColors.textTintBlue,
                      ))
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PinkTextField searchTextField() {
    return PinkTextField(
      focusNode: focusSearchTextField,
      strIconLeft: SvgIcons.search,
      hintText: 'Search',
      textEditingController: widget.searchEditingController,
      leftButtonFunc: () {
        setState(() {});
      },
      onChanged: (value) {
        setState(() {});
      },
    );
  }
}
