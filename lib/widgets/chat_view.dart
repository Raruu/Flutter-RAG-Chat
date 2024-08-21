import 'dart:math';

import 'package:flutter/foundation.dart';
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
import './chat_config/chat_config_card.dart';

class ChatView extends StatefulWidget {
  final LLMModel llmModel;
  final Function()? chatConfigFunc;
  final bool isChatConfigOpen;
  final bool mobileUI;
  final Function()? backFunc;
  const ChatView({
    super.key,
    required this.llmModel,
    this.chatConfigFunc,
    this.isChatConfigOpen = false,
    this.mobileUI = false,
    this.backFunc,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final TextEditingController _messageTextEditingController;
  late ChatDataList chatDataList;
  late List<Message> messageList;
  late final TextEditingController _seedEditingController;
  late final ScrollController _listViewMessageController;

  @override
  void initState() {
    _messageTextEditingController = TextEditingController();
    _listViewMessageController = ScrollController();
    _expandedEditingController = TextEditingController();
    _seedEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _messageTextEditingController.dispose();
    _listViewMessageController.dispose();
    _expandedEditingController.dispose();
    _seedEditingController.dispose();
    super.dispose();
  }

  void scrollDown() {
    if (_listViewMessageController.positions.isNotEmpty) {
      _listViewMessageController.animateTo(
        _listViewMessageController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.decelerate,
      );
    }
  }

  void addMessage(Message messageWidget, List<Message> messageList) {
    chatDataList.addToMessageList(messageWidget, chatDataList.currentData);
    chatDataList.notifyChatDataListner();
    Future.delayed(
      const Duration(milliseconds: 50),
      () => scrollDown(),
    );
  }

  void removeMessage(ChatData currentData, {int? removeIdx}) async {
    List<Message> currentMessageList = currentData.messageList;
    if (removeIdx == null) {
      removeIdx ??= currentMessageList.length - 1;
      if (currentMessageList[removeIdx].role == MessageRole.modelTyping) {
        currentMessageList.removeLast();
        removeIdx = currentMessageList.length - 1;
      }
    }
    var lastMessage = await chatDataList.removeToMessageList(
      removeIdx,
      chatData: currentData,
    );

    if (lastMessage.role == MessageRole.user &&
        currentMessageList == messageList &&
        _messageTextEditingController.text.isEmpty) {
      _messageTextEditingController.text = lastMessage.message;
    }
    if (currentMessageList.isEmpty) {
      chatDataList.remove(currentData);
    }
    chatDataList.notifyChatDataListner();
  }

  void generateText(BuildContext context, String prompt, ChatData currentData,
      List<Message> currentMessageList,
      {bool randomSeed = false}) {
    widget.llmModel
        .generateText(
            prompt: prompt,
            seed: randomSeed
                ? getRandomInt()
                : int.tryParse(_seedEditingController.text) ?? getRandomInt())
        .then(
      (value) {
        if (value == null) {
          removeMessage(currentData);
          return;
        }
        receiveMessage(value, currentMessageList);
      },
    );
    currentMessageList
        .add(Message(message: '', token: 0, role: MessageRole.modelTyping));
  }

  void regenerateText(int index, {String? query}) async {
    query ??= messageList[index].textData['query'];

    if (index <= messageList.length - 1 &&
        messageList[index].role == MessageRole.model) {
      chatDataList.removeToMessageList(index).then((value) => setState(() {}));
    }
    ChatData currentData = chatDataList.currentData;
    List<Message> currentMessageList = messageList;
    await widget.llmModel.onChatSettingsChanged();
    generateText(
        // ignore: use_build_context_synchronously
        context,
        query!,
        currentData,
        currentMessageList,
        randomSeed: true);
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

    generateText(context, query, currentData, currentMessageList);

    if (isEmpty) {
      chatDataList.currentData.title = query;
      widget.llmModel.parameters!.forEach(
          (key, value) => chatDataList.currentData.parameters[key] = value);

      chatDataList.add(chatDataList.currentData, context: context);
    }
  }

  void receiveMessage(
      Map<String, dynamic> textData, List<Message> messageList) {
    int token = textData.length ~/ 4;
    addMessage(
        Message(textData: textData, token: token, role: MessageRole.model),
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

  int getRandomInt() => Random().nextInt(2147483648);

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
          final RenderBox button = context.findRenderObject() as RenderBox;
          final RenderBox overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final Offset position =
              button.localToGlobal(Offset.zero, ancestor: overlay);
          showMenu(
            color: Theme.of(context).colorScheme.surface,
            elevation: 10,
            constraints: const BoxConstraints(minWidth: 225, maxWidth: 225),
            context: context,
            position: RelativeRect.fromLTRB(
              position.dx + 15,
              position.dy + button.size.height - 225,
              position.dx + button.size.width,
              position.dy,
            ),
            items: [
              PopupMenuItem(
                onTap: () {
                  Utils.dialogAddContext(
                      context: context,
                      chatDataList: chatDataList,
                      llmModel: widget.llmModel,
                      setState: setState);
                },
                child: Row(
                  children: [
                    SvgPicture.string(
                      SvgIcons.tablerFile,
                      width: 30,
                      height: 30,
                      colorFilter: ColorFilter.mode(
                        Utils.getDefaultTextColor(context)!,
                        BlendMode.srcIn,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(4)),
                    const Text('Add Knowledge')
                  ],
                ),
              ),
              PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seed',
                        style: TextStyle(
                            color: Utils.getDefaultTextColor(context)),
                      ),
                      PinkTextField(
                        maxLength: 10,
                        textEditingController: _seedEditingController,
                        textInputType: TextInputType.number,
                        hintText: 'Random',
                        strIconRight: SvgIcons.fluentSync,
                        tooltipIconRight: 'Get Random Seed Now',
                        rightButtonFunc: () => _seedEditingController.text =
                            getRandomInt().toString(),
                      )
                    ],
                  ))
            ],
          );
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
                      showContext:
                          (messageList[index].textData['query']?.isEmpty ??
                                  true)
                              ? null
                              : () => showContextDialog(index),
                      regenerate: () => regenerateText(index),
                      deleteFunc: () async {
                        if (await Utils.showDialogYesNo(
                            context: context,
                            title: const Text('Delete Message?'),
                            content: const Text('. . .'))) {
                          removeMessage(
                            chatDataList.currentData,
                            removeIdx: index,
                          );
                          widget.llmModel.onChatSettingsChanged();
                        }
                      },
                      userEditFunc: index >= messageList.length - 2
                          ? () async {
                              TextEditingController textEditingController =
                                  TextEditingController()
                                    ..text = messageList[index].message;
                              bool result = await Utils.showDialogYesNo(
                                context: context,
                                title: Container(
                                  constraints: BoxConstraints(
                                      minWidth:
                                          MediaQuery.sizeOf(context).width *
                                              1 /
                                              4),
                                  child: const Text(
                                    'Edit Message',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                content: PinkTextField(
                                  textEditingController: textEditingController,
                                  hintText: '',
                                  labelText: 'Message',
                                  backgroundColor: MyColors.bgTintBlue,
                                  multiLine: true,
                                ),
                              );
                              if (result) {
                                messageList[index].message =
                                    textEditingController.text;
                                widget.llmModel.onChatSettingsChanged();
                                if (messageList.length - 1 <= index) {
                                  regenerateText(index + 1,
                                      query: textEditingController.text);
                                }
                              }
                              textEditingController.dispose();
                            }
                          : null,
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool isExpandTopSection = false;
  late TextEditingController _expandedEditingController;
  late List<PopupMenuItem> popupMenuItems;

  ChatListCardWidget topSection() {
    popupMenuItems = [
      PopupMenuItem(
        onTap: () => chatDataList.importFromJson(context),
        child: Row(
          children: [
            SvgPicture.string(
              SvgIcons.uliImport,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Utils.getDefaultTextColor(context)!,
                BlendMode.srcIn,
              ),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            const Text('Import')
          ],
        ),
      ),
      PopupMenuItem(
        onTap: () => chatDataList.exportToJson(context),
        child: Row(
          children: [
            SvgPicture.string(
              SvgIcons.uliExport,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Utils.getDefaultTextColor(context)!,
                BlendMode.srcIn,
              ),
            ),
            const Padding(padding: EdgeInsets.all(4)),
            const Text('Export')
          ],
        ),
      )
    ];
    return ChatListCardWidget(
      splashColor: Colors.transparent,
      isShowExpandedChild: isExpandTopSection && messageList.isNotEmpty,
      chatTitle: chatDataList.currentData.title,
      chatSubtitle: '${chatDataList.currentData.totalToken} Tokens~',
      leftWidget: widget.mobileUI
          ? SizedBox(
              width: 24,
              child: IconButton(
                  onPressed: widget.backFunc,
                  padding: const EdgeInsets.all(0),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Utils.getDefaultTextColor(context),
                  )),
            )
          : null,
      rightWidget: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          widget.llmModel.informationWidget,
          if (!widget.mobileUI) const Padding(padding: EdgeInsets.all(10.0)),
          if (!widget.mobileUI)
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
                onPressed: widget.chatConfigFunc,
                icon: SvgPicture.string(
                  SvgIcons.fluentSettingsChat,
                  width: 30,
                  height: 30,
                  colorFilter: ColorFilter.mode(
                    Utils.getDefaultTextColor(context)!,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          if (!widget.mobileUI) const Padding(padding: EdgeInsets.all(10.0)),
          PopupMenuButton(
            offset: widget.mobileUI ? const Offset(0, 60) : const Offset(0, 40),
            constraints: const BoxConstraints(minWidth: 200),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Theme.of(context).colorScheme.surface,
            icon: SvgPicture.string(
              SvgIcons.dotsVertical,
              width: 30,
              height: 30,
              colorFilter: ColorFilter.mode(
                Utils.getDefaultTextColor(context)!,
                BlendMode.srcIn,
              ),
            ),
            itemBuilder: (context) => widget.mobileUI
                ? [
                    ...popupMenuItems,
                    PopupMenuItem(
                      onTap: widget.chatConfigFunc,
                      child: Row(
                        children: [
                          SvgPicture.string(
                            SvgIcons.fluentSettingsChat,
                            width: 30,
                            height: 30,
                            colorFilter: ColorFilter.mode(
                              Utils.getDefaultTextColor(context)!,
                              BlendMode.srcIn,
                            ),
                          ),
                          const Padding(padding: EdgeInsets.all(4)),
                          const Text('Chat Settings')
                        ],
                      ),
                    )
                  ]
                : [
                    ...popupMenuItems,
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
      onTap: widget.mobileUI
          ? () async {
              if (messageList.isEmpty) {
                isExpandTopSection = false;
                return;
              }
              _expandedEditingController.text = chatDataList.currentData.title;
              if (await Utils.showDialogYesNo(
                context: context,
                title: const Text(
                  'Rename',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                content: PinkTextField(
                  textEditingController: _expandedEditingController,
                  backgroundColor: MyColors.bgTintBlue,
                ),
              )) {
                renameChat();
              }
            }
          : () {
              if (messageList.isEmpty) {
                isExpandTopSection = false;
                return;
              }
              setState(() {
                _expandedEditingController.text =
                    chatDataList.currentData.title;
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
                        onPressed: renameChat,
                        child: const Text(
                          'Save',
                          style: TextStyle(color: MyColors.textTintPink),
                        ),
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

  void renameChat() {
    chatDataList.currentData.title = _expandedEditingController.text;
    isExpandTopSection = false;
    chatDataList.renameChat(_expandedEditingController.text);
    chatDataList.notifyChatDataListner();
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
              colorFilter: ColorFilter.mode(
                  Utils.getDefaultTextColor(context)!, BlendMode.srcIn),
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

  void showContextDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width * 3 / 4,
          child: SingleChildScrollView(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DefaultTextStyle.merge(
                    style: const TextStyle(fontSize: 18),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Query: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(messageList[index].textData['query']),
                          ],
                        ),
                        Row(
                          children: [
                            const Text(
                              'Seed: ',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(messageList[index].textData['seed'] ?? '-'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                ...List.generate(
                  messageList[index].textData['context1'].length,
                  (indexj) {
                    Map<String, dynamic> data =
                        messageList[index].textData['context1'][indexj];
                    String filename = data['filename'];
                    int pageNumber = data['page_number'];
                    double score = data['score'];

                    String contextData = data['context'];
                    return ChatConfigCard(
                      title: '[$pageNumber] $filename',
                      strIcon: SvgIcons.knowledge,
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'File Name: $filename',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  const Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 1.0)),
                                  IconButton(
                                    onPressed: () {
                                      var knowledge = chatDataList
                                          .currentData.knowledges
                                          .where((element) =>
                                              element['title'] == filename)
                                          .toList()
                                          .first;
                                      var value = kIsWeb
                                          ? knowledge['web_data']
                                          : knowledge['path'];
                                      Utils.openPdf(value,
                                          context: context,
                                          title: filename,
                                          pageAt: pageNumber);
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                  )
                                ],
                              ),
                              Text(
                                'Page: $pageNumber\nScore: $score\nContext:',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                              Text(contextData)
                            ],
                          ),
                        )
                      ],
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
