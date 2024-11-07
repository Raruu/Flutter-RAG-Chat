import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import 'package:open_filex/open_filex.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path/path.dart' as path_dart;

import '../controllers/chat_data_list.dart';
import '../services/llm_model.dart';
import '../widgets/pink_textfield.dart';
import 'kafuu_chino.dart';
import 'my_colors.dart';
import '../widgets/knowledge_widget.dart';
import 'svg_icons.dart';

class Utils<T> {
  static Map<String, dynamic> loadParametersWithDefaultParameters(
      Map<String, dynamic>? defaultParameters) {
    Map<String, dynamic> parameters = {};
    defaultParameters?.forEach(
      (key, value) {
        Type runTimeType = value.runtimeType;
        if ((runTimeType == List<double>) || (runTimeType == List<int>)) {
          parameters[key] = value[1];
        } else if (runTimeType == List<bool>) {
          parameters[key] = value.first;
        }
      },
    );
    return parameters;
  }

  static String sanitizeFilename(String filename) =>
      filename.replaceAll(RegExp(r'[\\/:\*\?"<>\|]'), '_');

  static bool isLightMode(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.light;

  static Color? getDefaultTextColor(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge!.color;

  static void navigateWithNewQueryParams(
      BuildContext context, Map<String, String> newQueryParams) {
    final currentUri = GoRouterState.of(context).uri;
    final path = Uri.parse(currentUri.toString()).path;
    final combinedQueryParams = {
      ...currentUri.queryParameters,
      ...newQueryParams,
    };
    final newUri = Uri(path: path, queryParameters: combinedQueryParams);
    context.go(newUri.toString());
  }

  static Map<String, List<String>> getURIParameters(BuildContext context) {
    return GoRouterState.of(context).uri.queryParametersAll;
  }

  static void viewKnowledge(
    dynamic value, {
    int pageAt = 0,
    BuildContext? context,
    String? title,
  }) async {
    if (kIsWeb) {
      final blob = html.Blob([value], 'application/pdf');
      final url = '${html.Url.createObjectUrlFromBlob(blob)}#page=$pageAt';
      html.window.open(url, '_blank');
      html.Url.revokeObjectUrl(url);
    } else {
      if (context != null) {
        PdfViewerController pdfViewerController = PdfViewerController();
        TextEditingController textEditingController = TextEditingController();
        bool isPdf = path_dart.extension(title!).toLowerCase() == '.pdf';
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_rounded)),
                    const Padding(padding: EdgeInsets.all(1.0)),
                    Text(title),
                  ],
                ),
                if (isPdf)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => pdfViewerController.zoomDown(),
                        icon: const Icon(Icons.zoom_out_rounded),
                      ),
                      IconButton(
                        onPressed: () => pdfViewerController.zoomUp(),
                        icon: const Icon(Icons.zoom_in_rounded),
                      ),
                      SizedBox(
                          width: 180,
                          child: PinkTextField(
                            textEditingController: textEditingController,
                            strIconLeft: SvgIcons.iconamoonPlayerPreviousFill,
                            textInputType: TextInputType.number,
                            hintText: '',
                            labelText: 'Page',
                            textAlign: TextAlign.center,
                            onChanged: (value) {
                              int goPage = int.tryParse(value) ??
                                  pdfViewerController.pageNumber!;

                              pdfViewerController.goToPage(
                                  pageNumber: goPage,
                                  duration: const Duration(microseconds: 0));
                            },
                            tooltipIconLeft: 'Previous',
                            leftButtonFunc: () => pdfViewerController.goToPage(
                                pageNumber:
                                    pdfViewerController.pageNumber! - 1),
                            strIconRight: SvgIcons.iconamoonPlayerNextFill,
                            tooltipIconRight: 'Next',
                            rightButtonFunc: () => pdfViewerController.goToPage(
                                pageNumber:
                                    pdfViewerController.pageNumber! + 1),
                          )),
                    ],
                  )
              ],
            ),
            content: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              height: MediaQuery.sizeOf(context).height,
              child: isPdf
                  ? PdfViewer.file(
                      value,
                      controller: pdfViewerController,
                      initialPageNumber: pageAt,
                      params: PdfViewerParams(
                        onPageChanged: (pageNumber) =>
                            textEditingController.text = pageNumber.toString(),
                      ),
                    )
                  : Image.file(File(value)),
            ),
          ),
        );
        textEditingController.dispose();
      } else {
        OpenFilex.open(value);
      }
    }
  }

  static void dialogAddContext(
      {required BuildContext context,
      required ChatDataList chatDataList,
      required LLMModel llmModel,
      required Function(Function()) setState}) async {
    var result = await addKnowledgeDialog(
      context: context,
      knowledge: {},
    );
    if (result.isNotEmpty) {
      var isAlreadyExist = chatDataList.currentData.knowledges.where(
        (element) => element['title'] == result['title'],
      );
      if (isAlreadyExist.isNotEmpty) {
        if (context.mounted) {
          showSnackBar(context, title: 'Already exist: ${result['title']}');
        }
        return;
      } else {
        kIsWeb
            ? await llmModel.addKnowledge(result['web_data'],
                webFileName: result['title'])
            : await llmModel.addKnowledge(result['path']);

        chatDataList.currentData.knowledges.add(result);
        setState(() {});
      }
    }
  }

  static String randomKafuuChino() {
    int rng = math.Random().nextInt(4);
    switch (rng) {
      case 0:
        return KafuuChino.disappointed;
      case 1:
        return KafuuChino.information;
      case 2:
        return KafuuChino.taskComplete;
      case 4:
        return KafuuChino.think;
      default:
        return KafuuChino.information;
    }
  }

  static bool isMobileSize(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide < 550;

  static void showSnackBar(
    BuildContext context, {
    String title = 'Not Implemented',
    String subTitle = 'See You Later. . .',
    double textSize = 20,
    Color? textColor,
    String? strIcon,
    Color? iconColor,
    double iconSize = 150,
    Duration duration = const Duration(seconds: 2),
    bool showCloseIcon = false,
    Color? closeIconColor,
    EdgeInsets padding = const EdgeInsets.all(0),
  }) {
    textColor ??= getDefaultTextColor(context);
    strIcon ??= randomKafuuChino();
    bool onHover = false;
    bool isMobile = isMobileSize(context);
    if (isMobile) {
      if (iconSize > 50) {
        iconSize = 50;
      }
      if (textSize > 16) {
        textSize = 16;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: isMobile ? null : SnackBarBehavior.floating,
        duration: const Duration(hours: 1),
        backgroundColor:
            isMobile ? MyColors.backgroundDark0 : Colors.transparent,
        shape: const Border(),
        elevation: isMobile ? null : 0,
        padding: isMobile
            ? null
            : const EdgeInsets.symmetric(horizontal: 66.0, vertical: 16.0),
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        content: ColorFiltered(
          colorFilter: isMobile
              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
              : const ColorFilter.mode(Colors.transparent, BlendMode.overlay),
          child: MouseRegion(
            onEnter: (event) => onHover = true,
            onExit: (event) => onHover = false,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: padding,
                constraints: BoxConstraints(
                  minHeight: iconSize,
                ),
                decoration: isMobile
                    ? null
                    : BoxDecoration(
                        boxShadow: const [
                          BoxShadow(
                            color: MyColors.bgSelectedBlue,
                            spreadRadius: 5,
                            blurRadius: 7,
                          )
                        ],
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.string(
                      strIcon,
                      colorFilter: ColorFilter.mode(
                          getDefaultTextColor(context)!, BlendMode.srcIn),
                      width: iconSize,
                      height: iconSize,
                    ),
                    const Padding(padding: EdgeInsets.all(8.0)),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                                color: textColor,
                                fontSize: textSize + 8,
                                fontWeight: FontWeight.w900),
                          ),
                          Text(subTitle,
                              style: TextStyle(
                                  color: textColor, fontSize: textSize)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      snackBarAnimationStyle: AnimationStyle(
        curve: Curves.easeIn,
        duration: const Duration(milliseconds: 300),
        reverseDuration: isMobile ? null : const Duration(seconds: 2),
        reverseCurve: Curves.easeOut,
      ),
    );

    Future.delayed(
      duration,
      () => Timer.periodic(
        const Duration(milliseconds: 200),
        (timer) {
          if (!onHover) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            timer.cancel();
          }
        },
      ),
    );
  }

  static Future<T?> showDialogYesNo<T>(
      {required BuildContext context, Widget? title, Widget? content}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: title,
        content: content,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
