import 'package:flutter/material.dart';
import 'package:flutter_rag_chat/models/llm_model.dart';
import 'package:flutter_rag_chat/utils/util.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import '../../../utils/my_colors.dart';
import 'data.dart';

class InformationWidget extends StatefulWidget {
  final Data data;
  const InformationWidget({
    super.key,
    required this.data,
  });

  @override
  State<InformationWidget> createState() => _InformationWidgetState();
}

class _InformationWidgetState extends State<InformationWidget> {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      hoverColor: MyColors.bgTintPink.withOpacity(0.5),
      highlightColor: MyColors.bgTintPink,
      padding: const EdgeInsets.all(7.0),
      onPressed: () {
        if (widget.data.gpuName == null &&
            widget.data.getInformationTryReconnect) {
          Utils.showSnackBar(
            context,
            title: 'Reconnecting',
            subTitle: 'Reconnecting',
            duration: const Duration(seconds: 1),
          );
          return widget.data.getInformation();
        }
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Information'),
              content: Consumer<LLMModel>(
                builder: (context, value, child) {
                  return SizedBox(
                    child: Wrap(
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            MemoryUsage(
                                title: 'VRAM',
                                memoryList: widget.data.vram ?? const [0, 0]),
                            MemoryUsage(
                              title: 'RAM',
                              memoryList: widget.data.ram ?? const [0, 0],
                              colorList: const [
                                MyColors.textTintPink,
                                MyColors.bgTintPink
                              ],
                            )
                          ],
                        ),
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 16.0, left: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GPU: ${widget.data.gpuName}'),
                                Text('Model ID: ${widget.data.modelId}'),
                                Text(
                                    'LLM Model in Memory: ${widget.data.llmModelMemoryUsage?.toStringAsFixed(2)} MB'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('CLOSE'),
                ),
              ],
            );
          },
        );
      },
      icon: Consumer<LLMModel>(
        builder: (context, value, child) {
          var vram = widget.data.vram ?? [0, 0];
          String vramPercent =
              'VRAM: ${(vram[0] / vram[1] * 100).toStringAsPrecision(2)}%';
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(widget.data.gpuName ?? 'Disconnected'),
              Text(vramPercent),
            ],
          );
        },
      ),
    );
  }
}

class MemoryUsage extends StatelessWidget {
  final String title;
  final List<double> memoryList;
  final List<Color> colorList;
  const MemoryUsage({
    super.key,
    required this.memoryList,
    this.colorList = const [
      MyColors.textTintBlue,
      MyColors.bgTintBlue,
    ],
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, double> memoryDataMap = {
      'Used': memoryList[0],
      'Free': memoryList[1] - memoryList[0],
    };
    var gbVramUsed = (memoryList[0] / 1024 * 1024).toStringAsPrecision(2);
    var gbVramTotal = (memoryList[1] / 1024 * 1024).toStringAsPrecision(2);
    return Column(
      children: [
        SizedBox(
          width: 100,
          height: 100,
          child: PieChart(
            dataMap: memoryDataMap,
            chartType: ChartType.ring,
            ringStrokeWidth: 10,
            centerText: '${gbVramUsed}GB\nof\n${gbVramTotal}GB',
            legendOptions: const LegendOptions(showLegends: false),
            chartValuesOptions: const ChartValuesOptions(
              showChartValueBackground: false,
              showChartValues: false,
            ),
            colorList: colorList,
          ),
        ),
        Text(title),
      ],
    );
  }
}