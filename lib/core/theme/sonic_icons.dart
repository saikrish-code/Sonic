import 'package:flutter/material.dart';

/// Helper to instantiate IconData dynamically from stored database codePoints.
IconData getDynamicIcon(int codePoint) {
  // ignore: non_const_argument_for_const_parameter
  return IconData(codePoint, fontFamily: 'MaterialIcons');
}
