import "package:flutter/material.dart";
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

  @override
  void initState() {
    _messageTextEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _messageTextEditingController.dispose();
    super.dispose();
  }

  void sendMessage() {
    if (_messageTextEditingController.text.trim().isEmpty) {
      return;
    }
    bool isEmpty = messageList.isEmpty;
    int token = _messageTextEditingController.text.length ~/ 4;
    chatDataList.currentData.totalToken += token;
    String prompt = _messageTextEditingController.text;
    _messageTextEditingController.clear();

    setState(
      () => messageList
          .add(Message(message: prompt, token: token, role: MessageRole.user)),
    );

    widget.llmModel.generateText(prompt).then(
      (value) {
        if (value == null) {
          return;
        }
        receiveMessage(value);
      },
    );
    if (isEmpty) {
      chatDataList.currentData.title = prompt;
      widget.llmModel.parameters!.forEach(
          (key, value) => chatDataList.currentData.parameters[key] = value);

      chatDataList.add(chatDataList.currentData);
    }
  }

  void receiveMessage(String text) {
    int token = text.length ~/ 4;
    setState(() => messageList
        .add(Message(message: text, token: token, role: MessageRole.model)));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatDataList>(
      builder: (context, value, child) {
        chatDataList = value;
        messageList = chatDataList.currentData.messageList;
        return Column(
          children: [
            ChatListCardWidget(
              chatTitle: chatDataList.currentData.title,
              chatSubtitle: '${chatDataList.currentData.totalToken} Tokens~',
              rightWidget: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    hoverColor: MyColors.bgTintPink.withOpacity(0.5),
                    highlightColor: MyColors.bgTintPink,
                    padding: const EdgeInsets.all(7.0),
                    onPressed: () {},
                    icon: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('data1'),
                        Text('data2'),
                      ],
                    ),
                  ),
                  const Padding(padding: EdgeInsets.all(10.0)),
                  Ink(
                    decoration: ShapeDecoration(
                      shape: CircleBorder(),
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
                  IconButton(
                      hoverColor: MyColors.bgTintPink.withOpacity(0.5),
                      highlightColor: MyColors.bgTintPink,
                      onPressed: () {},
                      icon: SvgPicture.string(
                        SvgIcons.dotsVertical,
                        width: 30,
                        height: 30,
                      )),
                ],
              ),
            ),
            Expanded(
              child: messageList.isEmpty
                  ? chatWhenEmpty(context)
                  : ListView.builder(
                      itemCount: messageList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5.0, horizontal: 10.0),
                          child: Container(
                            padding: messageList[index].role == MessageRole.user
                                ? const EdgeInsets.only(left: 32.0)
                                : const EdgeInsets.only(right: 32.0),
                            alignment:
                                messageList[index].role == MessageRole.user
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
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 1 / 3),
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
                leftButtonFunc: () {},
                rightButtonFunc: sendMessage,
                onEditingComplete: sendMessage,
              ),
            )
          ],
        );
      },
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