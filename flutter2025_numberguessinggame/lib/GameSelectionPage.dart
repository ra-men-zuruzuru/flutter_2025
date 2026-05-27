import 'package:flutter/material.dart';
import 'package:flutter2025_numberguessinggame/HighLowDifficultyPage.dart';

class GameSelectionPage extends StatelessWidget {
  const GameSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ゲーム選択')),
      body: Column(
        children: const [
          Expanded(child: HighLowDifficultyPage()),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Text(
              'Hit & BlowはHigh&Lowで3連勝すると解放されるボーナスチャレンジです。',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
