import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/my_colors.dart';

class ParameterSlider extends StatefulWidget {
  final String textKey;
  final List<num> values;
  final Function(num value) onChanged;
  final Function(num value)? onChangeEnd;
  late final bool isInt;
  ParameterSlider({
    super.key,
    required this.textKey,
    required this.values,
    required this.onChanged,
    this.onChangeEnd,
  }) {
    isInt = values.runtimeType == List<int>;
  }

  @override
  State<ParameterSlider> createState() => _ParameterSliderState();
}

class _ParameterSliderState extends State<ParameterSlider> {
  double get parameterValue => widget.values[1].toDouble();
  set parameterValue(dynamic value) {
    if (widget.isInt) {
      value = value.toInt();
    }
    widget.onChanged(value);
    widget.values[1] = value;
    setState(() {});
  }

  late final TextEditingController textValueController;

  @override
  void initState() {
    textValueController = TextEditingController();
    textValueController.text = parameterValue.toStringAsPrecision(4);

    super.initState();
  }

  @override
  void dispose() {
    textValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInt) {
      textValueController.text = parameterValue.toInt().toStringAsFixed(0);
    } else {
      textValueController.text = parameterValue.toStringAsFixed(3);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          decoration: BoxDecoration(
              color: MyColors.bgTintBlue,
              borderRadius: BorderRadius.circular(12.0)),
          child: Text(
            widget.textKey,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: MyColors.textTintBlue),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Slider(
                thumbColor: MyColors.bgTintPink,
                activeColor: MyColors.bgSelectedBlue,
                min: widget.values[0].toDouble(),
                value: parameterValue,
                max: widget.values[2].toDouble(),
                onChanged: (value) => parameterValue = value,
                onChangeEnd: widget.onChangeEnd,
              ),
            ),
            SizedBox(
              width: 75,
              child: TextField(
                controller: textValueController,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MyColors.textTintBlue),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9.,-]'))
                ],
                onChanged: (val) {
                  var value = double.tryParse(val);
                  value ??= 0.0;
                  if (value > widget.values[2]) {
                    value = widget.values[2] as double;
                  } else if (value < widget.values[0]) {
                    value = widget.values[0] as double;
                  }
                  parameterValue = value;
                },
                decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(0),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24.0)),
                        borderSide: BorderSide.none),
                    fillColor: MyColors.bgTintPink,
                    filled: true),
              ),
            ),
          ],
        )
      ],
    );
  }
}
