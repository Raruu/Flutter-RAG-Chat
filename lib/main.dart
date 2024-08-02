import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_page.dart';
import 'models/llm_model.dart';
import './models/chat_data_list.dart';

void main() async {
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
            );
          },
        )
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
