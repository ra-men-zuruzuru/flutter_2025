import 'package:flutter/material.dart';

enum DifficultyLevel { easy, normal, hard }

class Difficulty {
  final DifficultyLevel level;
  final String name;
  final int maxNumber;
  final int attempts;
  final Color color;

  const Difficulty({
    required this.level,
    required this.name,
    required this.maxNumber,
    required this.attempts,
    required this.color,
  });

  static const easy = Difficulty(
    level: DifficultyLevel.easy,
    name: "かんたん",
    maxNumber: 10,
    attempts: 3,
    color: Color(0xFF4CAF50), // Green
  );

  static const normal = Difficulty(
    level: DifficultyLevel.normal,
    name: "ふつう",
    maxNumber: 50,
    attempts: 5,
    color: Color(0xFF2196F3), // Blue
  );

  static const hard = Difficulty(
    level: DifficultyLevel.hard,
    name: "むずかしい",
    maxNumber: 100,
    attempts: 7,
    color: Color(0xFFF44336), // Red
  );

  static List<Difficulty> get values => [easy, normal, hard];
}
