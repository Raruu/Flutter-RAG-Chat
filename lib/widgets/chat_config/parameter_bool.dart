import 'package:flutter/material.dart';

import '../../utils/my_colors.dart';

class ParameterBool extends StatefulWidget {
  final String textKey;
  final List<bool> value;
  final Function(bool value) onChanged;
  const ParameterBool({
    super.key,
    required this.textKey,
    required this.onChanged,
    required this.value,
  });

  @override
  State<ParameterBool> createState() => _ParameterBoolState();
}

class _ParameterBoolState extends State<ParameterBool> {
  bool get parameterValue => widget.value[0];
  set parameterValue(bool value) {
    widget.onChanged(value);
    widget.value[0] = value;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Switch(
              activeColor: MyColors.bgTintPink,
              thumbIcon: WidgetStatePropertyAll(
                  Icon(parameterValue ? Icons.check : Icons.close)),
              value: parameterValue,
              onChanged: (value) => parameterValue = value,
            ),
          )
        ],
      ),
    );
  }
}
