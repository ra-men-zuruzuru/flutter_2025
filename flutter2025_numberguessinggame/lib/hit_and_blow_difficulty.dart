import 'package:flutter/material.dart';

class HitAndBlowDifficulty {
  final String name;
  final int digits;
  final Color color;

  const HitAndBlowDifficulty({
    required this.name,
    required this.digits,
    required this.color,
  });

  static const digit3 = HitAndBlowDifficulty(
    name: "3桁 (3 Digits)",
    digits: 3,
    color: Colors.green,
  );

  static const digit4 = HitAndBlowDifficulty(
    name: "4桁 (4 Digits)",
    digits: 4,
    color: Colors.blue,
  );

  static List<HitAndBlowDifficulty> get values => [digit3, digit4];
}
