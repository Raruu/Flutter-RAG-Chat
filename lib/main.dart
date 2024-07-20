import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import './screens/home_screens_desktop.dart';
import 'models/llm_model.dart';
import './models/chat_data_list.dart';

void main() {
  LLMModel llmModel = LLMModel();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => ChatDataList()),
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
            return HomePageDesktop(
              llmModel: llmModel,
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
