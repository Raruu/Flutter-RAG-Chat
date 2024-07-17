import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

import 'kafuu_chino.dart';
import 'my_colors.dart';

class Utils<T> {
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

  static void showSnackBar(
    BuildContext context, {
    String title = 'Not Implemented',
    String subTitle = 'See You Later. . .',
    double textSize = 20,
    Color textColor = Colors.black,
    String? strIcon,
    Color? iconColor,
    double iconSize = 150,
    Duration duration = const Duration(seconds: 2),
    bool showCloseIcon = false,
    Color? closeIconColor,
    EdgeInsets padding = const EdgeInsets.all(0),
  }) {
    strIcon ??= randomKafuuChino();
    bool onHover = false;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(hours: 1),
        backgroundColor: Colors.transparent,
        shape: const Border(),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 66.0, vertical: 16.0),
        showCloseIcon: showCloseIcon,
        closeIconColor: closeIconColor,
        content: MouseRegion(
          onEnter: (event) => onHover = true,
          onExit: (event) => onHover = false,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: padding,
              constraints: BoxConstraints(
                minHeight: iconSize,
              ),
              decoration: BoxDecoration(
                boxShadow: const [
                  BoxShadow(
                    color: MyColors.bgSelectedBlue,
                    spreadRadius: 5,
                    blurRadius: 7,
                  )
                ],
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.string(
                    strIcon,
                    colorFilter:
                        const ColorFilter.mode(Colors.black, BlendMode.srcIn),
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
      snackBarAnimationStyle: AnimationStyle(
        curve: Curves.easeIn,
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(seconds: 2),
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
