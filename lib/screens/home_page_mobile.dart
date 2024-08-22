import "package:flutter/material.dart";
import 'package:flutter_rag_chat/utils/util.dart';
import 'package:flutter_rag_chat/widgets/general_settings.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../utils/my_colors.dart';
import '../utils/svg_icons.dart';
import '../widgets/chat_list/chat_list.dart';
import '../models/llm_models/llm_model.dart';
import '../models/chat_data_list.dart';

class HomePageMobile extends StatefulWidget {
  final ChatDataList chatDataList;
  final LLMModel llmModel;
  final int initialMenuSelected;
  final TextEditingController searchEditingController;
  final Function() toggleDarkMode;
  const HomePageMobile({
    super.key,
    required this.llmModel,
    required this.initialMenuSelected,
    required this.chatDataList,
    required this.searchEditingController,
    required this.toggleDarkMode,
  });

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  late int _menuSelected;
  int get menuSelected => _menuSelected;
  set menuSelected(int value) {
    Utils.navigateWithNewQueryParams(
        context, {'menuSelected': value.toString()});
    if (value != _menuSelected) {
      pageController.animateToPage(value,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart);
    }
    setState(() => _menuSelected = value);
  }

  late final PageController pageController;

  void onChatLoaded() => context.goNamed('mobile_chatview',
      queryParameters: Utils.getURIParameters(context));

  @override
  void initState() {
    _menuSelected =
        widget.initialMenuSelected < 0 ? 0 : widget.initialMenuSelected;
    pageController = PageController(keepPage: true, initialPage: _menuSelected);
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.backgroundDark0,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: PageView(
                  controller: pageController,
                  onPageChanged: (value) => menuSelected = value,
                  children: [
                    Consumer<ChatDataList>(
                      builder: (context, value, child) => Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: ChatList(
                            mobileUI: true,
                            searchEditingController:
                                widget.searchEditingController,
                            chatDataList: widget.chatDataList,
                            newChatFunction: () {
                              widget.chatDataList.newChat(
                                  llmModel: widget.llmModel, context: context);
                            },
                            loadedDataCallback: onChatLoaded,
                            llmModel: widget.llmModel),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GeneralSettings(
                        llmModel: widget.llmModel,
                        toggleDarkMode: widget.toggleDarkMode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  SizedBox bottomNavigationBar() {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.tight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    onPressed: () => menuSelected = 0,
                    padding: const EdgeInsets.all(4),
                    highlightColor: MyColors.textTintBlue,
                    icon: SvgPicture.string(
                      fit: BoxFit.fill,
                      _menuSelected == 0
                          ? SvgIcons.chatFill
                          : SvgIcons.chatBold,
                      colorFilter: ColorFilter.mode(
                          _menuSelected == 0
                              ? MyColors.bgSelectedBlue
                              : Colors.white,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
                const Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                )
              ],
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                    color: MyColors.bgTintBlue.withOpacity(0.5),
                    borderRadius: BorderRadiusDirectional.circular(26)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 32,
                      width: 32,
                      child: IconButton(
                        onPressed: () {
                          widget.chatDataList.newChat(
                              llmModel: widget.llmModel, context: context);
                          onChatLoaded();
                        },
                        padding: const EdgeInsets.all(4),
                        highlightColor: MyColors.textTintBlue,
                        icon: SvgPicture.string(
                          SvgIcons.plus,
                          fit: BoxFit.fill,
                          colorFilter: const ColorFilter.mode(
                              Colors.white, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    const Text(
                      'New Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            fit: FlexFit.tight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 32,
                  width: 32,
                  child: IconButton(
                    onPressed: () => menuSelected = 1,
                    padding: const EdgeInsets.all(4),
                    highlightColor: MyColors.textTintBlue,
                    icon: SvgPicture.string(
                      fit: BoxFit.fill,
                      _menuSelected == 1
                          ? SvgIcons.fluentSettingsMultipleFill
                          : SvgIcons.fluentSettingsMultiple,
                      colorFilter: ColorFilter.mode(
                          _menuSelected == 1
                              ? MyColors.bgSelectedBlue
                              : Colors.white,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
                const Text(
                  'Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
