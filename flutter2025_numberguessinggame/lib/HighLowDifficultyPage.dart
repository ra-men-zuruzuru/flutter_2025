import 'package:flutter/material.dart';

class HighLowDifficultyPage extends StatelessWidget {
  const HighLowDifficultyPage({super.key});

  void _showGameDescription(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ゲーム説明'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'High & Low',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('持ち金100からスタートします。'),
                Text('ラウンド開始前に、持ち金以内で掛け金を決めます。'),
                Text('正解すると、ミス回数に応じた倍率分のコインを獲得します。'),
                Text('失敗すると、掛け金を失います。持ち金が0になるとゲーム終了です。'),
                SizedBox(height: 16),
                Text(
                  'ボーナスチャレンジ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('High & Lowで3連勝するとHit & Blowに挑戦できます。'),
                Text('参加費は50コイン、3桁の数字を8手以内に当てるチャレンジです。'),
                Text('少ない手数でクリアするほど、ランクと報酬が高くなります。'),
                SizedBox(height: 16),
                Text('ランキング', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('ゲーム終了時に、スコアをオンラインランキングへ投稿できます。'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

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
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/high_low_ranking');
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('ランキングを見る'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showGameDescription(context),
                  icon: const Icon(Icons.help_outline),
                  label: const Text('遊び方'),
                ),
              ],
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
