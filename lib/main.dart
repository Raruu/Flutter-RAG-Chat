import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/widgets/chat_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'screens/home_page.dart';
import 'models/llm_model.dart';
import './models/chat_data_list.dart';
import 'widgets/chat_config.dart';
import './utils/my_colors.dart';

void main() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  setPathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  WidgetsFlutterBinding.ensureInitialized();
  ChatDataList chatDataList = ChatDataList();
  LLMModel llmModel =
      LLMModel(chatDataList, prefs: await SharedPreferences.getInstance());
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => chatDataList),
      ChangeNotifierProvider(create: (context) => llmModel)
    ],
    child: MyApp(
      llmModel: llmModel,
    ),
  ));
}

class MyApp extends StatefulWidget {
  final LLMModel llmModel;
  const MyApp({super.key, required this.llmModel});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    _router = GoRouter(
      routes: [
        GoRoute(
            path: "/",
            name: "home",
            builder: (context, state) {
              var querys = state.uri.queryParametersAll;
              return HomePage(
                llmModel: widget.llmModel,
                chatDataList: widget.llmModel.chatDataList,
                initialCtnRightOpen: querys['isCtnRightOpen']?.first == 'true',
                initialMenuSelected:
                    int.tryParse(querys['menuSelected']?.first ?? '-1')!,
                initialChatId: querys['chat']?.first ?? '0',
                toggleDarkMode: toggleDarkMode,
              );
            },
            routes: [
              GoRoute(
                path: "mobile_chatview",
                name: 'mobile_chatview',
                builder: (context, state) {
                  backFunc() {
                    widget.llmModel.chatDataList.currentSelected = -1;
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed('home',
                          queryParameters: state.uri.queryParametersAll);
                    }
                  }

                  return Scaffold(
                    body: SafeArea(
                      child: ChatView(
                        llmModel: widget.llmModel,
                        mobileUI: true,
                        backFunc: backFunc,
                        chatConfigFunc: () {
                          showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            enableDrag: true,
                            isScrollControlled: true,
                            builder: (context) => SizedBox(
                              height: MediaQuery.sizeOf(context).height * 3 / 4,
                              child: ChatConfig(
                                llmModel: widget.llmModel,
                                chatDataList: widget.llmModel.chatDataList,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              )
            ]),
      ],
      initialLocation: "/",
    );
    prefs = widget.llmModel.prefs;
    themeMode =
        ThemeMode.values.byName(prefs.getString('theme_mode') ?? 'light');
    super.initState();
  }

  late final SharedPreferences prefs;
  late ThemeMode themeMode;
  void toggleDarkMode() {
    setState(() {
      themeMode =
          themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
    prefs.setString('theme_mode', themeMode.name);
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter RAG-Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: MyColors.bgTintBlue,
          surface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: MyColors.bgTintBlue,
          brightness: Brightness.dark,
          surface: MyColors.backgroundDark1,
        ),
        useMaterial3: true,
        fontFamily: 'Montserrat',
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
