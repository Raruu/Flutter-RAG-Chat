import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'kafuu_chino.dart';
import 'my_colors.dart';

class Utils {
  static void showSnackBar(
    BuildContext context, {
    String title = 'Title',
    String subTitle = 'subtitle',
    double textSize = 20,
    Color textColor = Colors.black,
    String strIcon = KafuuChino.information,
    Color? iconColor,
    double iconSize = 150,
    Duration duration = const Duration(seconds: 2),
    bool showCloseIcon = false,
    Color? closeIconColor,
    EdgeInsets padding = const EdgeInsets.all(0),
  }) {
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
          child: Container(
            padding: padding,
            width: double.infinity,
            height: iconSize,
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
                Column(
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
                        style: TextStyle(color: textColor, fontSize: textSize)),
                  ],
                )
              ],
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
}