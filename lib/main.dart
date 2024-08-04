import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/widgets/chat_view.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_strategy/url_strategy.dart';

import 'screens/home_page.dart';
import 'models/llm_model.dart';
import './models/chat_data_list.dart';
import 'widgets/chat_config.dart';

void main() async {
  setPathUrlStrategy(); // see https://pub.dev/packages/url_strategy
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

class MyApp extends StatelessWidget {
  late final GoRouter _router;
  final LLMModel llmModel;

  MyApp({super.key, required this.llmModel}) {
    _router = GoRouter(
      routes: [
        GoRoute(
            path: "/",
            name: "home",
            builder: (context, state) {
              var querys = state.uri.queryParametersAll;
              return HomePage(
                llmModel: llmModel,
                chatDataList: llmModel.chatDataList,
                initialCtnRightOpen: querys['isCtnRightOpen']?.first == 'true',
                initialMenuSelected:
                    int.tryParse(querys['menuSelected']?.first ?? '-1')!,
                initialChatId: querys['chat']?.first ?? '0',
              );
            },
            routes: [
              GoRoute(
                path: "mobile_chatview",
                name: 'mobile_chatview',
                builder: (context, state) {
                  backFunc() {
                    llmModel.chatDataList.currentSelected = -1;
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.goNamed('home',
                          queryParameters: state.uri.queryParametersAll);
                    }
                  }

                  return Scaffold(
                    body: ChatView(
                      llmModel: llmModel,
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
                              llmModel: llmModel,
                              chatDataList: llmModel.chatDataList,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              )
            ]),
      ],
      initialLocation: "/",
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flutter RAG-Chat',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          // textTheme: GoogleFonts.montserratTextTheme(),
          fontFamily: 'Montserrat'),
      routerConfig: _router,
    );
  }
}
