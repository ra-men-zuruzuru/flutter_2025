import 'package:flutter/material.dart';

class HighLowDifficultyPage extends StatelessWidget {
  const HighLowDifficultyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.show_chart, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'High & Low',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/high_low_ranking');
                },
                icon: const Icon(Icons.emoji_events),
                label: const Text('ランキングを見る'),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '持ち金100から始めて、各ラウンドで掛け金を決めます。正解したら倍率分を獲得、失敗したら掛け金を失います。',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/game');
                },
                child: const Text('ゲーム開始'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
