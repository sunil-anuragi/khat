import 'dart:ui';

import 'package:flutter/material.dart';

class ColorConstants {
  static const themeColor = Color.fromARGB(255, 0, 0, 0);
  static Map<int, Color> swatchColor = {
    50: themeColor.withOpacity(0.1),
    100: themeColor.withOpacity(0.2),
    200: themeColor.withOpacity(0.3),
    300: themeColor.withOpacity(0.4),
    400: themeColor.withOpacity(0.5),
    500: themeColor.withOpacity(0.6),
    600: themeColor.withOpacity(0.7),
    700: themeColor.withOpacity(0.8),
    800: themeColor.withOpacity(0.9),
    900: themeColor.withOpacity(1),
  };
  static const primaryColor = Color(0xff203152);
  static const greyColor = Color(0xffaeaeae);
  static const greyColor2 = Color(0xffE8E8E8);
  static const green = Colors.green;
  static const red = Colors.red;
  static const white = Colors.white;
  static const blackgrey = Color.fromARGB(255, 39, 39, 39);
}
