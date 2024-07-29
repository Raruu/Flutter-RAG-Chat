import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:pdfrx/pdfrx.dart';

import '../utils/my_colors.dart';
import '../utils/svg_icons.dart';
import '../utils/util.dart';
import './pink_textfield.dart';
import '../models/llm_model.dart';

class KnowledgeWidget extends StatefulWidget {
  final Map<String, dynamic> knowledge;
  final List<Map<String, dynamic>> knowledges;
  final LLMModel llmModel;
  const KnowledgeWidget({
    super.key,
    required this.knowledge,
    required this.knowledges,
    required this.llmModel,
  });

  @override
  State<KnowledgeWidget> createState() => _KnowledgeWidgetState();
}

class _KnowledgeWidgetState extends State<KnowledgeWidget> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
              color: MyColors.textTintPink,
              width: 1.0,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: BorderRadius.circular(7.0)),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(
                color: isHover ? MyColors.bgSelectedBlue : Colors.transparent,
                width: 2.0),
            borderRadius: BorderRadius.circular(5.0)),
        child: InkWell(
          onTap: () {
            knowledgeDialog(
              context: context,
              knowledge: widget.knowledge,
              deleteFunc: () {
                Utils.showDialogYesNo(
                        context: context, title: const Text('Delete'))
                    .then((value) async {
                  if (value) {
                    await widget.llmModel.deleteKnowledge
                        ?.call(widget.knowledge['title']);
                    if (widget.knowledges.remove(widget.knowledge) &&
                        context.mounted) {
                      Navigator.pop(context, null);
                    }
                  }
                });
              },
            );
          },
          onHover: (value) => setState(() {
            isHover = value;
          }),
          hoverColor: MyColors.bgTintBlue,
          splashColor: Colors.white,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 6.0, horizontal: 10.0),
            child: Text(widget.knowledge['title']!),
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> knowledgeDialog({
  required BuildContext context,
  required Map<String, dynamic> knowledge,
  Function()? deleteFunc,
}) async {
  TextEditingController pathEditingController = TextEditingController()
    ..text = knowledge.isNotEmpty ? knowledge['path']! : '';
  String path = pathEditingController.text;
  bool isFileExists = kIsWeb ? false : await File(path).exists();
  Uint8List? fileUint8 = knowledge['web_data'];

  PdfViewerController pdfViewerController = PdfViewerController();
  TextEditingController pageNumberEditingController = TextEditingController();
  bool isHoverPageController = false;

  var result = await showDialog(
    // ignore: use_build_context_synchronously
    context: context,
    builder: (context) => AlertDialog(
      title: Text(knowledge.isEmpty ? 'Add Knowledge' : knowledge['title']!),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Wrap(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width * 2 / 3,
                        child: PinkTextField(
                          textEditingController: pathEditingController,
                          hintText: '',
                          labelText: kIsWeb ? 'Title' : 'Path',
                          tooltipIconRight: 'Pick PDF',
                          strIconRight: SvgIcons.tablerFile,
                          rightButtonFunc: () async {
                            FilePickerResult? result =
                                await FilePicker.platform.pickFiles(
                              allowMultiple: false,
                              type: FileType.custom,
                              allowedExtensions: ['pdf'],
                            );

                            if (result != null) {
                              pathEditingController.text = (kIsWeb
                                  ? result.files.first.name
                                  : result.paths.first)!;
                              path = pathEditingController.text;
                              if (!kIsWeb) {
                                isFileExists = await File(path).exists();
                              }
                              if (kIsWeb) {
                                fileUint8 = result.files.first.bytes;
                              }
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(2.0)),
                      Visibility(
                        visible: isFileExists || fileUint8 != null,
                        child: Row(
                          children: [
                            Visibility(
                              visible: deleteFunc != null,
                              child: IconButton(
                                tooltip: 'Delete',
                                icon: const Icon(Icons.delete_forever_outlined),
                                onPressed: deleteFunc,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Open With',
                              icon: const Icon(Icons.open_in_new_rounded),
                              onPressed: () =>
                                  Utils.openPdf(kIsWeb ? fileUint8 : path),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Visibility(
                    visible: isFileExists || fileUint8 != null,
                    child: SizedBox(
                      width: MediaQuery.sizeOf(context).width * 2 / 3,
                      height: MediaQuery.sizeOf(context).height * 2 / 3,
                      child: Stack(
                        children: [
                          isFileExists || fileUint8 != null
                              ? kIsWeb
                                  ? PdfViewer.data(
                                      Uint8List.fromList(fileUint8!),
                                      sourceName: path,
                                      controller: pdfViewerController,
                                      params: PdfViewerParams(
                                        enableTextSelection: true,
                                        backgroundColor: Colors.transparent,
                                        onPageChanged: (pageNumber) =>
                                            pageNumberEditingController.text =
                                                pageNumber.toString(),
                                      ),
                                    )
                                  : PdfViewer.file(
                                      path,
                                      controller: pdfViewerController,
                                      params: PdfViewerParams(
                                        enableTextSelection: true,
                                        backgroundColor: Colors.transparent,
                                        onPageChanged: (pageNumber) =>
                                            pageNumberEditingController.text =
                                                pageNumber.toString(),
                                      ),
                                    )
                              : const SizedBox(),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: isHoverPageController ? 1 : 0.5,
                              child: MouseRegion(
                                onEnter: (event) => setState(
                                    () => isHoverPageController = true),
                                onExit: (event) => setState(
                                    () => isHoverPageController = false),
                                child: Container(
                                  decoration: BoxDecoration(
                                      color:
                                          MyColors.bgTintBlue.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Wrap(
                                    direction: Axis.horizontal,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            pdfViewerController.zoomDown(),
                                        icon:
                                            const Icon(Icons.zoom_out_rounded),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            pdfViewerController.zoomUp(),
                                        icon: const Icon(Icons.zoom_in_rounded),
                                      ),
                                      SizedBox(
                                          width: 180,
                                          child: PinkTextField(
                                            textEditingController:
                                                pageNumberEditingController,
                                            strIconLeft: SvgIcons
                                                .iconamoonPlayerPreviousFill,
                                            textInputType: TextInputType.number,
                                            hintText: '',
                                            labelText: 'Page',
                                            textAlign: TextAlign.center,
                                            onChanged: (value) {
                                              int goPage =
                                                  int.tryParse(value) ??
                                                      pdfViewerController
                                                          .pageNumber!;

                                              pdfViewerController.goToPage(
                                                  pageNumber: goPage,
                                                  duration: const Duration(
                                                      microseconds: 0));
                                            },
                                            tooltipIconLeft: 'Previous',
                                            leftButtonFunc: () =>
                                                pdfViewerController.goToPage(
                                                    pageNumber:
                                                        pdfViewerController
                                                                .pageNumber! -
                                                            1),
                                            strIconRight: SvgIcons
                                                .iconamoonPlayerNextFill,
                                            tooltipIconRight: 'Next',
                                            rightButtonFunc: () =>
                                                pdfViewerController.goToPage(
                                                    pageNumber:
                                                        pdfViewerController
                                                                .pageNumber! +
                                                            1),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Close'),
        ),
        TextButton(
          onPressed: () async {
            path = pathEditingController.text;
            if (fileUint8 != null || await File(path).exists()) {
              if (kIsWeb) {
                knowledge['title'] = path;
                knowledge['path'] = path;
                knowledge['web_data'] = fileUint8;
              } else {
                knowledge['title'] = path.split(Platform.pathSeparator).last;
                knowledge['path'] = path;
              }
              if (context.mounted) {
                Navigator.pop(context, knowledge);
              }
            } else {
              if (context.mounted) {
                Utils.showSnackBar(context,
                    title: 'Not Exist: $path', subTitle: 'Or Is It?');
              }
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  pathEditingController.dispose();
  pageNumberEditingController.dispose();
  return result ?? {}.cast<String, String>();
}
