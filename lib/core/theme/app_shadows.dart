import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  /// Small shadow — for cards at rest
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Medium shadow — for elevated cards, FAB
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Large shadow — for dialogs, bottom sheets
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
