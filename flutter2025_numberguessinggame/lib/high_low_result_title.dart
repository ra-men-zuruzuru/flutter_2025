import 'package:flutter/material.dart';

class HighLowResultStats {
  final double score;
  final int reachedRound;
  final double maxMoney;
  final int winRounds;
  final int loseRounds;
  final int maxWinStreak;
  final int bonusChallengeCount;
  final int bonusClearCount;
  final String? bestBonusRank;

  const HighLowResultStats({
    required this.score,
    required this.reachedRound,
    required this.maxMoney,
    required this.winRounds,
    required this.loseRounds,
    required this.maxWinStreak,
    required this.bonusChallengeCount,
    required this.bonusClearCount,
    required this.bestBonusRank,
  });
}

class HighLowResultTitle {
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const HighLowResultTitle({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });

  static HighLowResultTitle evaluate(HighLowResultStats stats) {
    if (stats.score <= 0) {
      return const HighLowResultTitle(
        label: 'すっからかんチャレンジャー',
        description: '最後まで勝負に出た証です。次の一手で巻き返しましょう。',
        color: Color(0xFF78909C),
        icon: Icons.hourglass_empty,
      );
    }

    if (stats.bestBonusRank == 'S') {
      return const HighLowResultTitle(
        label: 'ボーナス職人',
        description: 'Hit & Blowを鮮やかに決めた、寄り道上手な勝負師です。',
        color: Color(0xFFFFB300),
        icon: Icons.workspace_premium,
      );
    }

    if (stats.maxWinStreak >= 5) {
      return const HighLowResultTitle(
        label: '連勝の読み師',
        description: '流れを読み切り、勝ちを重ねた見事なプレイです。',
        color: Color(0xFF7E57C2),
        icon: Icons.auto_graph,
      );
    }

    if (stats.score >= 500) {
      return const HighLowResultTitle(
        label: '金色の勝負師',
        description: '大きく増やして帰ってきた、まぶしい勝負勘です。',
        color: Color(0xFFFFA000),
        icon: Icons.savings,
      );
    }

    if (stats.score >= 250) {
      return const HighLowResultTitle(
        label: '伸び盛り投資家',
        description: '増やし方が見えてきています。次はさらに上へ。',
        color: Color(0xFF26A69A),
        icon: Icons.trending_up,
      );
    }

    if (stats.loseRounds == 0 && stats.winRounds >= 3) {
      return const HighLowResultTitle(
        label: '堅実な予言者',
        description: '失敗なしで勝ちを拾った、丁寧な読みの持ち主です。',
        color: Color(0xFF43A047),
        icon: Icons.verified,
      );
    }

    if (stats.bonusChallengeCount > 0) {
      return const HighLowResultTitle(
        label: '挑戦好きの勝負師',
        description: 'ボーナスへ踏み込んだ、その攻めっ気が光ります。',
        color: Color(0xFFFF7043),
        icon: Icons.local_fire_department,
      );
    }

    if (stats.score >= 100) {
      return const HighLowResultTitle(
        label: '慎重な勝負師',
        description: '無理をしすぎず、きっちり勝負をまとめました。',
        color: Color(0xFF5C6BC0),
        icon: Icons.shield,
      );
    }

    return const HighLowResultTitle(
      label: '再挑戦の芽',
      description: '次に伸びる余地あり。まだ勝負は始まったばかりです。',
      color: Color(0xFF8BC34A),
      icon: Icons.eco,
    );
  }
}
