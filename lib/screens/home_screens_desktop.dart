import "package:flutter/material.dart";
import 'package:flutter_rag_chat/utils/util.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../utils/my_colors.dart';
import '../utils/svg_icons.dart';
import '../widgets/desktop_menu_button.dart';
import '../widgets/pink_textfield.dart';
import '../widgets/chat_list.dart';
import '../widgets/chat_view.dart';
import '../models/llm_model.dart';
import '../models/chat_data_list.dart';
import '../widgets/chat_config.dart';

class HomePageDesktop extends StatefulWidget {
  final LLMModel llmModel;
  final int initialMenuSelected;
  final bool initialCtnRightOpen;
  const HomePageDesktop({
    super.key,
    required this.llmModel,
    required this.initialMenuSelected,
    required this.initialCtnRightOpen,
  });

  @override
  State<HomePageDesktop> createState() => _HomePageDesktopState();
}

class _HomePageDesktopState extends State<HomePageDesktop> {
  bool menuExtended = false;
  bool menuHovered = false;
  void menuHover(bool value) => setState(() => menuHovered = value);

  late int _menuSelected;
  int get menuSelected => _menuSelected;
  set menuSelected(int value) {
    context.goNamed('home', queryParameters: {
      ...GoRouterState.of(context).uri.queryParametersAll,
      'menuSelected': value.toString()
    });
    setState(() => _menuSelected = (_menuSelected == value) ? -1 : value);
  }

  late bool isCtnRightOpen;

  late final TextEditingController _searchEditingController;

  double _tmpCtnLeftWidth = 0;
  double _tmpCtnRightWidth = 0;
  late ChatDataList chatDataList;

  void showChatConfigMenu() {
    isCtnRightOpen = !isCtnRightOpen;
    context.goNamed('home', queryParameters: {
      ...GoRouterState.of(context).uri.queryParametersAll,
      'isCtnRightOpen': isCtnRightOpen.toString()
    });
    setState(() {});
  }

  @override
  void initState() {
    chatDataList = ChatDataList();
    _searchEditingController = TextEditingController();
    _menuSelected = widget.initialMenuSelected;
    isCtnRightOpen = widget.initialCtnRightOpen;
    super.initState();
  }

  @override
  void dispose() {
    _searchEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    double menuWidth = menuExtended || menuHovered ? 200 : 75;
    double chatWidth = width - menuWidth;

    int ctnLeftFlex = menuSelected > -1 ? 1 : 0,
        ctnMidFlex = isCtnRightOpen ? 4 : 3,
        ctnRightFlex = isCtnRightOpen ? 2 : 0;
    double ctnLeftWidth = (ctnLeftFlex * (width - menuWidth)) /
        (ctnLeftFlex + ctnMidFlex + ctnRightFlex);

    if (ctnLeftWidth < 300 && ctnLeftFlex > 0) {
      ctnLeftWidth = 300;
    }
    if (ctnLeftWidth != 0) _tmpCtnLeftWidth = ctnLeftWidth;
    // double ctnMidWidth =
    //     (ctnMidFlex * (width - menuWidth)) / (ctnLeftFlex + ctnMidFlex);
    double ctnRightWidth = (ctnRightFlex * (width - menuWidth)) /
        (ctnLeftFlex + ctnMidFlex + ctnRightFlex);
    if (ctnRightWidth < 410 && ctnRightFlex > 0) {
      ctnRightWidth = 410;
    }
    if (ctnRightWidth != 0) _tmpCtnRightWidth = ctnRightWidth;
    return Scaffold(
      backgroundColor: MyColors.backgroundDark,
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            menuBar(menuWidth),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Easing.standardDecelerate,
              width: chatWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Consumer<ChatDataList>(
                builder: (context, value, child) {
                  chatDataList = value;
                  return Row(
                    children: [
                      ctnLeft(ctnLeftWidth),
                      ctnMid(),
                      ctnRight(ctnRightWidth),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  AnimatedContainer ctnRight(double ctnRightWidth) {
    return AnimatedContainer(
      width: ctnRightWidth,
      curve: Easing.standardDecelerate,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isCtnRightOpen ? 1 : 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              width: _tmpCtnRightWidth,
              child: Align(
                alignment: Alignment.topCenter,
                child: ChatConfig(
                  llmModel: widget.llmModel,
                  chatDataList: chatDataList,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Flexible ctnMid() {
    return Flexible(
      fit: FlexFit.tight,
      child: ChatView(
        llmModel: widget.llmModel,
        functionChatConfig: showChatConfigMenu,
        isChatConfigOpen: isCtnRightOpen,
      ),
    );
  }

  Widget loadCtnLeft(int value) {
    if (value == 0) {
      return ChatList(
        newChatFunction: () => chatDataList.newChat(),
        searchEditingController: _searchEditingController,
        chatDataList: chatDataList,
        llmModel: widget.llmModel,
      );
    }
    if (value == 1) {
      return settingList();
    }
    return const SizedBox();
  }

  AnimatedContainer ctnLeft(double ctnLeftWidth) {
    return AnimatedContainer(
      width: ctnLeftWidth,
      curve: Easing.standardDecelerate,
      duration: const Duration(milliseconds: 200),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: menuSelected > -1 ? 1 : 0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: _tmpCtnLeftWidth,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: loadCtnLeft(menuSelected),
            ),
          ),
        ),
      ),
    );
  }

  Widget settingList() {
    return StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.string(SvgIcons.modelIcon),
              const Text(
                'Model Provider',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
              ),
            ],
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: MyColors.bgTintBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton(
                        value: widget.llmModel.provider,
                        dropdownColor: MyColors.bgTintBlue,
                        borderRadius: BorderRadius.circular(10),
                        hint: const Text('Provider'),
                        items: widget.llmModel.providersList
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (value) {
                          widget.llmModel.provider = value!;
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(4)),
                PinkTextField(
                  textEditingController:
                      widget.llmModel.urlTextEditingController,
                  hintText: '',
                  labelText: 'URL',
                  backgroundColor: MyColors.bgTintBlue,
                  onChanged: (value) => widget.llmModel.finishUrlEditing(),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  AnimatedContainer menuBar(double menuWidth) {
    return AnimatedContainer(
      width: menuWidth,
      duration: const Duration(milliseconds: 200),
      curve: Easing.standardDecelerate,
      padding: const EdgeInsets.only(left: 13.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          MouseRegion(
            onEnter: (event) => menuHover(true),
            onExit: (event) => menuHover(false),
            child: DesktopMenuButton(
              stringSvg: SvgIcons.lightMode,
              text: "Light Mode",
              textVisibilty: menuExtended || menuHovered,
              onTap: () {
                Utils.showSnackBar(context);
              },
            ),
          ),
          const Spacer(),
          MouseRegion(
            onEnter: (event) => menuHover(true),
            onExit: (event) => menuHover(false),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DesktopMenuButton(
                  stringSvg: SvgIcons.chatBold,
                  stringSvgSelected: SvgIcons.chatFill,
                  text: "Chat",
                  textVisibilty: menuExtended || menuHovered,
                  onTap: () {
                    menuSelected = 0;
                  },
                  isSelected: menuSelected == 0 ? true : false,
                ),
                const Padding(padding: EdgeInsets.all(16.0)),
                DesktopMenuButton(
                  stringSvg: SvgIcons.fluentSettingsMultiple,
                  stringSvgSelected: SvgIcons.fluentSettingsMultipleFill,
                  text: "Settings",
                  textVisibilty: menuExtended || menuHovered,
                  onTap: () {
                    menuSelected = 1;
                  },
                  isSelected: menuSelected == 1 ? true : false,
                ),
              ],
            ),
          ),
          const Spacer(
            flex: 5,
          ),
          DesktopMenuButton(
            stringSvg: SvgIcons.menu,
            text: "Menu",
            textVisibilty: menuExtended || menuHovered,
            onTap: () {
              menuExtended = !menuExtended;
              setState(() {});
            },
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
