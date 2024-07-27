import "package:flutter/material.dart";
import 'package:flutter_rag_chat/utils/util.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../utils/svg_icons.dart';
import '../widgets/pink_textfield.dart';
import 'chat_list/chat_list_card_widget.dart';
import '../models/message.dart';
import '../models/llm_model.dart';
import './chat_bubble.dart';
import '../utils/my_colors.dart';
import '../models/chat_data_list.dart';
import 'chat_bubble_typing.dart';
import '../models/chat_data.dart';

class ChatView extends StatefulWidget {
  final LLMModel llmModel;
  final Function()? functionChatConfig;
  final bool isChatConfigOpen;
  const ChatView({
    super.key,
    required this.llmModel,
    this.functionChatConfig,
    required this.isChatConfigOpen,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final TextEditingController _messageTextEditingController;
  late ChatDataList chatDataList;
  late List<Message> messageList;
  late final ScrollController _listViewMessageController;

  @override
  void initState() {
    _messageTextEditingController = TextEditingController();
    _listViewMessageController = ScrollController();
    _expandedEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _messageTextEditingController.dispose();
    _listViewMessageController.dispose();
    _expandedEditingController.dispose();
    super.dispose();
  }

  void scrollDown() {
    _listViewMessageController.animateTo(
      _listViewMessageController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.decelerate,
    );
  }

  void addMessage(Message messageWidget, List<Message> messageList) {
    if (messageList.isNotEmpty &&
        messageList.last.role == MessageRole.modelTyping) {
      messageList.removeLast();
    }
    messageList.add(messageWidget);
    chatDataList.notifyChatDataListner();
    Future.delayed(
      const Duration(milliseconds: 50),
      () => scrollDown(),
    );
  }

  void revertMessage(List<Message> currentMessageList, ChatData currentData) {
    var lastMessage = currentMessageList.removeLast();
    if (lastMessage.role == MessageRole.modelTyping) {
      lastMessage = currentMessageList.removeLast();
    }
    if (lastMessage.role == MessageRole.user &&
        currentMessageList == messageList) {
      _messageTextEditingController.text = lastMessage.message;
    }
    if (currentMessageList.isEmpty) {
      chatDataList.remove(currentData);
    }
    chatDataList.notifyChatDataListner();
  }

  void sendMessage() {
    if (_messageTextEditingController.text.trim().isEmpty) {
      return;
    }
    bool isEmpty = messageList.isEmpty;
    int token = _messageTextEditingController.text.length ~/ 4;
    chatDataList.currentData.totalToken += token;
    String query = _messageTextEditingController.text;
    _messageTextEditingController.clear();

    ChatData currentData = chatDataList.currentData;
    List<Message> currentMessageList = messageList;
    addMessage(Message(message: query, token: token, role: MessageRole.user),
        currentMessageList);

    String prompt = query;

    widget.llmModel.generateText(context, prompt).then(
      (value) {
        if (value == null) {
          revertMessage(messageList, currentData);
          return;
        }
        receiveMessage(value, currentMessageList);
      },
    );
    currentMessageList
        .add(Message(message: '', token: 0, role: MessageRole.modelTyping));
    if (isEmpty) {
      chatDataList.currentData.title = prompt;
      widget.llmModel.parameters!.forEach(
          (key, value) => chatDataList.currentData.parameters[key] = value);

      chatDataList.add(chatDataList.currentData);
    }
  }

  void receiveMessage(String text, List<Message> messageList) {
    int token = text.length ~/ 4;
    addMessage(Message(message: text, token: token, role: MessageRole.model),
        messageList);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatDataList>(
      builder: (context, value, child) {
        chatDataList = value;
        messageList = chatDataList.currentData.messageList;
        return Column(
          children: [
            topSection(),
            midSection(context),
            bottomSection(context),
          ],
        );
      },
    );
  }

  Container bottomSection(BuildContext context) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 1 / 3),
      padding: const EdgeInsets.all(8.0),
      child: PinkTextField(
        textEditingController: _messageTextEditingController,
        hintText: 'Type Here...',
        multiLine: true,
        strIconLeft: SvgIcons.attachment,
        strIconRight: SvgIcons.sendDuoTone,
        iconSizeLeft: 28,
        iconSizeRight: 28,
        borderRadiusCircular: 32.0,
        leftButtonFunc: () {
          Utils.dialogAddContext(
              context: context,
              chatDataList: chatDataList,
              llmModel: widget.llmModel,
              setState: setState);
        },
        tooltipIconLeft: 'Add Context',
        rightButtonFunc: sendMessage,
        tooltipIconRight: 'Send Message',
        onEditingComplete: sendMessage,
        newLineOnEnter: false,
      ),
    );
  }

  Expanded midSection(BuildContext context) {
    return Expanded(
      child: messageList.isEmpty
          ? chatWhenEmpty(context)
          : ListView.builder(
              controller: _listViewMessageController,
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                if (messageList[index].role == MessageRole.modelTyping) {
                  return const Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    child: ChatBubbleTyping(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 10.0),
                  child: Container(
                    padding: messageList[index].role == MessageRole.user
                        ? const EdgeInsets.only(left: 32.0)
                        : const EdgeInsets.only(right: 32.0),
                    alignment: messageList[index].role == MessageRole.user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ChatBubble(
                      text: messageList[index].message,
                      token: messageList[index].token,
                      role: messageList[index].role,
                      backgroundColor:
                          messageList[index].role == MessageRole.user
                              ? MyColors.bgTintPink
                              : MyColors.bgTintBlue,
                      // TODO Regenerate
                      regenerate: () {},
                      deleteFunc: () async {
                        if (await Utils.showDialogYesNo(
                            context: context,
                            title: const Text('Delete Message?'),
                            content: const Text('. . .'))) {
                          messageList.remove(messageList[index]);
                          widget.llmModel.onChatSettingsChanged?.call();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool isExpandTopSection = false;
  late TextEditingController _expandedEditingController;
  ChatListCardWidget topSection() {
    return ChatListCardWidget(
      splashColor: Colors.transparent,
      isShowExpandedChild: isExpandTopSection && messageList.isNotEmpty,
      chatTitle: chatDataList.currentData.title,
      chatSubtitle: '${chatDataList.currentData.totalToken} Tokens~',
      rightWidget: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.llmModel.informationWidget,
          const Padding(padding: EdgeInsets.all(10.0)),
          Ink(
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: widget.isChatConfigOpen
                  ? MyColors.bgTintPink.withOpacity(0.5)
                  : Colors.transparent,
            ),
            child: IconButton(
                hoverColor: MyColors.bgTintPink.withOpacity(0.5),
                highlightColor: MyColors.bgTintPink,
                onPressed: widget.functionChatConfig,
                icon: SvgPicture.string(
                  SvgIcons.fluentSettingsChat,
                  width: 30,
                  height: 30,
                )),
          ),
          const Padding(padding: EdgeInsets.all(10.0)),
          PopupMenuButton(
            offset: const Offset(0, 40),
            color: Colors.white,
            icon: SvgPicture.string(
              SvgIcons.dotsVertical,
              width: 30,
              height: 30,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Text('Not Implemented'),
              ),
            ],
          )
        ],
      ),
      heightOfExpandedChild: 120,
      expandingCurve: Curves.easeInOutQuart,
      expandDuration: const Duration(milliseconds: 500),
      mouseCursor: messageList.isEmpty
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onTap: () {
        if (messageList.isEmpty) {
          isExpandTopSection = false;
          return;
        }
        setState(() {
          _expandedEditingController.text = chatDataList.currentData.title;
          isExpandTopSection = !isExpandTopSection;
        });
      },
      expandedChild: Padding(
        padding: const EdgeInsets.only(top: 63),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 72.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rename',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                PinkTextField(
                  textEditingController: _expandedEditingController,
                  backgroundColor: MyColors.bgTintBlue,
                ),
                const Padding(padding: EdgeInsets.all(4.0)),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          isExpandTopSection = false;
                        }),
                        child: const Text('Cancle'),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(2.0)),
                    Expanded(
                      child: ElevatedButton(
                        style: const ButtonStyle(
                          backgroundColor:
                              WidgetStatePropertyAll(MyColors.bgTintPink),
                          overlayColor:
                              WidgetStatePropertyAll(MyColors.bgTintBlue),
                        ),
                        onPressed: () {
                          chatDataList.currentData.title =
                              _expandedEditingController.text;
                          isExpandTopSection = false;
                          chatDataList.notifyChatDataListner();
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Center chatWhenEmpty(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.fitHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(
              SvgIcons.rengeShiranai,
              colorFilter:
                  const ColorFilter.mode(Colors.black, BlendMode.srcIn),
              height: MediaQuery.sizeOf(context).height * 2 / 3,
              width: MediaQuery.sizeOf(context).height * 2 / 3,
            ),
            const Text(
              'OniiChan, Chat is Empty',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
            ),
            const Text(
              'Try make a conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            )
          ],
        ),
      ),
    );
  }
}
