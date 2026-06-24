import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter2025_numberguessinggame/HitAndBlowGamePage.dart';
import 'package:flutter2025_numberguessinggame/high_low_result_title.dart';
import 'package:flutter2025_numberguessinggame/main.dart';

void main() {
  testWidgets('shows game selection tabs and High & Low start screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('High & Low'), findsWidgets);
    expect(find.textContaining('Hit & BlowはHigh&Lowで3連勝'), findsOneWidget);
    expect(find.text('ゲーム開始'), findsOneWidget);
    expect(find.text('遊び方'), findsOneWidget);
    expect(find.byIcon(Icons.show_chart), findsWidgets);

    await tester.tap(find.text('遊び方'));
    await tester.pumpAndSettle();

    expect(find.text('ゲーム説明'), findsOneWidget);
    expect(find.text('ボーナスチャレンジ'), findsOneWidget);

    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('ゲーム説明'), findsNothing);
  });

  testWidgets('asks for confirmation before leaving High & Low', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('ゲーム開始'));
    await tester.pumpAndSettle();

    expect(find.text('ROUND：1'), findsOneWidget);
    expect(find.text('フェーズ：かんたん'), findsOneWidget);
    expect(find.text('範囲：1〜10'), findsOneWidget);
    expect(find.text('0ミス'), findsOneWidget);
    expect(find.text('0倍'), findsOneWidget);
    expect(find.text('全ミス'), findsOneWidget);
    expect(find.text('持ち金'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('メニューに戻りますか？'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('ROUND：1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();

    expect(find.text('ゲーム開始'), findsOneWidget);
  });

  test('Hit & Blow bonus rank rewards are calculated from attempts', () {
    expect(HitAndBlowBonusRules.rankForAttempts(3).label, 'S');
    expect(HitAndBlowBonusRules.rankForAttempts(3).reward, 100);
    expect(HitAndBlowBonusRules.rankForAttempts(4).label, 'A');
    expect(HitAndBlowBonusRules.rankForAttempts(4).reward, 60);
    expect(HitAndBlowBonusRules.rankForAttempts(5).label, 'B');
    expect(HitAndBlowBonusRules.rankForAttempts(5).reward, 30);
    expect(HitAndBlowBonusRules.rankForAttempts(8).label, 'C');
    expect(HitAndBlowBonusRules.rankForAttempts(8).reward, 10);
  });

  test('High & Low result titles are evaluated by priority', () {
    HighLowResultTitle titleFor({
      double score = 120,
      int winRounds = 0,
      int loseRounds = 1,
      int maxWinStreak = 0,
      int bonusChallengeCount = 0,
      String? bestBonusRank,
    }) {
      return HighLowResultTitle.evaluate(
        HighLowResultStats(
          score: score,
          reachedRound: 1,
          maxMoney: score,
          winRounds: winRounds,
          loseRounds: loseRounds,
          maxWinStreak: maxWinStreak,
          bonusChallengeCount: bonusChallengeCount,
          bonusClearCount: bestBonusRank == null ? 0 : 1,
          bestBonusRank: bestBonusRank,
        ),
      );
    }

    expect(titleFor(score: 0).label, 'すっからかんチャレンジャー');
    expect(titleFor(score: 120, bestBonusRank: 'S').label, 'ボーナス職人');
    expect(titleFor(score: 120, maxWinStreak: 5).label, '連勝の読み師');
    expect(titleFor(score: 500).label, '金色の勝負師');
    expect(titleFor(score: 80).label, '再挑戦の芽');
  });

  test('High & Low share text includes result details', () {
    const title = HighLowResultTitle(
      label: '金色の勝負師',
      description: '大きく増やして帰ってきた、まぶしい勝負勘です。',
      color: Colors.amber,
      icon: Icons.savings,
    );
    const stats = HighLowResultStats(
      score: 100.5,
      reachedRound: 7,
      maxMoney: 250,
      winRounds: 4,
      loseRounds: 1,
      maxWinStreak: 3,
      bonusChallengeCount: 1,
      bonusClearCount: 0,
      bestBonusRank: null,
    );

    final shareText = HighLowResultShareText.build(title: title, stats: stats);

    expect(shareText, contains('High & Lowで「金色の勝負師」を獲得！'));
    expect(shareText, contains('最終スコアは100.5'));
    expect(shareText, contains('到達ラウンドは7'));
    expect(shareText, contains('最高持ち金250'));
    expect(shareText, contains('#HighAndLow #数当てカジノ'));
  });

  testWidgets('Hit & Blow bonus screen shows history hints and missions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HitAndBlowGamePage()));

    expect(find.text('入力履歴'), findsOneWidget);
    expect(find.text('まだ回答はありません'), findsOneWidget);
    expect(find.text('ヒントショップ'), findsOneWidget);
    expect(find.text('ミッション'), findsOneWidget);
  });
}
