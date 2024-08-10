import 'package:flutter/material.dart';

import '../utils/my_colors.dart';

class NiceDropDownButton extends StatelessWidget {
  final String? value;
  final dynamic items;
  final void Function(dynamic value)? onChanged;
  final Color color;
  const NiceDropDownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.color = MyColors.bgTintBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton(
            iconEnabledColor: Colors.black,
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Colors.black),
            value: value,
            dropdownColor: color,
            borderRadius: BorderRadius.circular(10),
            hint: const Text('Provider'),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
