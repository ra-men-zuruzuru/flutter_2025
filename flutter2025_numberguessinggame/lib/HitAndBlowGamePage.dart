import 'dart:math';

import 'package:flutter/material.dart';

class HitAndBlowBonusRules {
  static const int digits = 3;
  static const int maxAttempts = 8;
  static const int entryFee = 50;

  static HitAndBlowRank rankForAttempts(int attempts) {
    if (attempts <= 3) {
      return const HitAndBlowRank('S', 100, Color(0xFFFFC107));
    }
    if (attempts == 4) {
      return const HitAndBlowRank('A', 60, Color(0xFF66BB6A));
    }
    if (attempts == 5) {
      return const HitAndBlowRank('B', 30, Color(0xFF42A5F5));
    }
    return const HitAndBlowRank('C', 10, Color(0xFFBDBDBD));
  }
}

class HitAndBlowRank {
  final String label;
  final int reward;
  final Color color;

  const HitAndBlowRank(this.label, this.reward, this.color);
}

class HitAndBlowBonusArgs {
  final double currentMoney;

  const HitAndBlowBonusArgs({required this.currentMoney});
}

class HitAndBlowBonusResult {
  final double updatedMoney;
  final bool isCleared;
  final String? rank;
  final int reward;
  final Map<String, bool> missions;

  const HitAndBlowBonusResult({
    required this.updatedMoney,
    required this.isCleared,
    required this.rank,
    required this.reward,
    required this.missions,
  });
}

class GuessResult {
  final String guess;
  final int hit;
  final int blow;

  const GuessResult({
    required this.guess,
    required this.hit,
    required this.blow,
  });
}

class HintLog {
  final String text;
  final int cost;

  const HintLog({required this.text, required this.cost});
}

class HitAndBlowGamePage extends StatefulWidget {
  const HitAndBlowGamePage({super.key});

  @override
  State<HitAndBlowGamePage> createState() => _HitAndBlowGamePageState();
}

class _HitAndBlowGamePageState extends State<HitAndBlowGamePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();

  List<int> _targetNumbers = [];
  final List<GuessResult> _history = [];
  final List<HintLog> _hintHistory = [];
  final Set<int> _excludedDigits = {};
  final Set<int> _revealedPositions = {};

  double _money = 0;
  String _errorMessage = '';
  bool _isInitialized = false;
  bool _isGameOver = false;
  bool _isCleared = false;
  bool _usedHint = false;
  bool _allowReturn = false;
  bool _firstGuessTwoOrMore = false;
  bool _repeatedConsecutiveGuess = false;
  bool _hadBlowZero = false;
  HitAndBlowRank? _rank;

  int get _remainingAttempts =>
      HitAndBlowBonusRules.maxAttempts - _history.length;

  Map<String, bool> get _missions => {
    '5手以内にクリア': _isCleared && _history.length <= 5,
    'ヒントを使わずクリア': _isCleared && !_usedHint,
    '最初の予想で数字を2つ以上当てる': _isCleared && _firstGuessTwoOrMore,
    '同じ数字を連続で使わずクリア': _isCleared && !_repeatedConsecutiveGuess,
    '1回もブロー0を出さずにクリア': _isCleared && !_hadBlowZero,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is HitAndBlowBonusArgs) {
      _money = args.currentMoney;
    }

    _targetNumbers = _generateUniqueNumbers(HitAndBlowBonusRules.digits);
    _isInitialized = true;
  }

  List<int> _generateUniqueNumbers(int count) {
    final list = List.generate(10, (i) => i);
    list.shuffle(_random);
    return list.sublist(0, count);
  }

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _checkGuess() {
    if (_isGameOver) {
      return;
    }

    setState(() {
      _errorMessage = '';
    });

    final input = _controller.text;
    if (input.length != HitAndBlowBonusRules.digits) {
      setState(() {
        _errorMessage = '${HitAndBlowBonusRules.digits}桁の数字を入力してください';
      });
      return;
    }

    if (int.tryParse(input) == null) {
      setState(() {
        _errorMessage = '数字を入力してください';
      });
      return;
    }

    if (input.split('').toSet().length != input.length) {
      setState(() {
        _errorMessage = '同じ数字は使えません';
      });
      return;
    }

    final guessDigits = input.split('').map(int.parse).toList();
    var hit = 0;
    var blow = 0;

    for (var i = 0; i < guessDigits.length; i++) {
      if (guessDigits[i] == _targetNumbers[i]) {
        hit++;
      } else if (_targetNumbers.contains(guessDigits[i])) {
        blow++;
      }
    }

    setState(() {
      if (_history.isNotEmpty && _history.first.guess == input) {
        _repeatedConsecutiveGuess = true;
      }
      if (_history.isEmpty && hit + blow >= 2) {
        _firstGuessTwoOrMore = true;
      }
      if (blow == 0) {
        _hadBlowZero = true;
      }

      _history.insert(0, GuessResult(guess: input, hit: hit, blow: blow));
      _controller.clear();
      _focusNode.requestFocus();

      if (hit == HitAndBlowBonusRules.digits) {
        _completeChallenge();
      } else if (_history.length >= HitAndBlowBonusRules.maxAttempts) {
        _failChallenge();
      }
    });
  }

  void _completeChallenge() {
    _rank = HitAndBlowBonusRules.rankForAttempts(_history.length);
    _money += _rank!.reward;
    _isCleared = true;
    _isGameOver = true;
  }

  void _failChallenge() {
    _isCleared = false;
    _isGameOver = true;
  }

  void _returnToHighLow() {
    _allowReturn = true;
    Navigator.pop(
      context,
      HitAndBlowBonusResult(
        updatedMoney: _money,
        isCleared: _isCleared,
        rank: _rank?.label,
        reward: _rank?.reward ?? 0,
        missions: _missions,
      ),
    );
  }

  bool _canBuyHint(int cost) => !_isGameOver && _money >= cost;

  void _buyContainsHint() {
    _askNumber('含まれるか確認する数字', (number) {
      _spendHint(
        cost: 100,
        text: _targetNumbers.contains(number)
            ? '$number は答えに含まれます。'
            : '$number は答えに含まれません。',
      );
    });
  }

  void _buyPositionHint() {
    final positionController = TextEditingController();
    final digitController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('位置の正誤確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: positionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '位置（1〜3）'),
            ),
            TextField(
              controller: digitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '数字（0〜9）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final position = int.tryParse(positionController.text);
              final digit = int.tryParse(digitController.text);
              Navigator.pop(context);

              if (position == null ||
                  position < 1 ||
                  position > HitAndBlowBonusRules.digits ||
                  digit == null ||
                  digit < 0 ||
                  digit > 9) {
                setState(() {
                  _errorMessage = '位置と数字を正しく入力してください';
                });
                return;
              }

              final isCorrect = _targetNumbers[position - 1] == digit;
              _spendHint(
                cost: 200,
                text: '$position桁目が$digit: ${isCorrect ? '正しい' : '違います'}。',
              );
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _buyExcludeHint() {
    final candidates = List.generate(10, (i) => i)
        .where((digit) => !_targetNumbers.contains(digit))
        .where((digit) => !_excludedDigits.contains(digit))
        .toList();

    if (candidates.isEmpty) {
      setState(() {
        _errorMessage = 'これ以上除外できる数字がありません';
      });
      return;
    }

    candidates.shuffle(_random);
    final digit = candidates.first;
    _excludedDigits.add(digit);
    _spendHint(cost: 300, text: '$digit は答えに使われていません。');
  }

  void _buyRevealHint() {
    final candidates = List.generate(
      HitAndBlowBonusRules.digits,
      (i) => i,
    ).where((position) => !_revealedPositions.contains(position)).toList();

    if (candidates.isEmpty) {
      setState(() {
        _errorMessage = 'これ以上開示できる桁がありません';
      });
      return;
    }

    candidates.shuffle(_random);
    final position = candidates.first;
    _revealedPositions.add(position);
    _spendHint(
      cost: 500,
      text: '${position + 1}桁目は ${_targetNumbers[position]} です。',
    );
  }

  void _askNumber(String title, void Function(int number) onSubmit) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: '数字（0〜9）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final number = int.tryParse(controller.text);
              Navigator.pop(context);
              if (number == null || number < 0 || number > 9) {
                setState(() {
                  _errorMessage = '0〜9の数字を入力してください';
                });
                return;
              }
              onSubmit(number);
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  void _spendHint({required int cost, required String text}) {
    if (!_canBuyHint(cost)) {
      setState(() {
        _errorMessage = 'コインが足りません';
      });
      return;
    }

    setState(() {
      _money -= cost;
      _usedHint = true;
      _errorMessage = '';
      _hintHistory.insert(0, HintLog(text: text, cost: cost));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowReturn,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _returnToHighLow();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('ボーナスチャレンジ')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BonusStatusCard(
                  money: _formatMoney(_money),
                  attempts: _history.length,
                  remainingAttempts: _remainingAttempts,
                ),
                const SizedBox(height: 16),
                if (_isGameOver)
                  _BonusResultCard(isCleared: _isCleared, rank: _rank),
                if (!_isGameOver) _buildGuessForm(),
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 16),
                _HistoryList(history: _history),
                const SizedBox(height: 16),
                _HintAndMissionArea(
                  money: _money,
                  hintsEnabled: !_isGameOver,
                  hints: _hintHistory,
                  missions: _missions,
                  onContains: _buyContainsHint,
                  onPosition: _buyPositionHint,
                  onExclude: _buyExcludeHint,
                  onReveal: _buyRevealHint,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _returnToHighLow,
                  child: const Text('High&Lowへ戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuessForm() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            maxLength: HitAndBlowBonusRules.digits,
            decoration: const InputDecoration(
              labelText: '3桁の数字',
              border: OutlineInputBorder(),
              counterText: '',
            ),
            onSubmitted: (_) => _checkGuess(),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton(onPressed: _checkGuess, child: const Text('判定')),
      ],
    );
  }
}

class _BonusStatusCard extends StatelessWidget {
  final String money;
  final int attempts;
  final int remainingAttempts;

  const _BonusStatusCard({
    required this.money,
    required this.attempts,
    required this.remainingAttempts,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Text('持ち金: $money', style: const TextStyle(fontSize: 18)),
            Text('手数: $attempts/${HitAndBlowBonusRules.maxAttempts}'),
            Text('残り: $remainingAttempts手'),
          ],
        ),
      ),
    );
  }
}

class _BonusResultCard extends StatelessWidget {
  final bool isCleared;
  final HitAndBlowRank? rank;

  const _BonusResultCard({required this.isCleared, required this.rank});

  @override
  Widget build(BuildContext context) {
    final color = isCleared ? rank!.color : Colors.red.shade200;
    final title = isCleared ? '${rank!.label}ランク達成！' : 'チャレンジ失敗';
    final message = isCleared
        ? '報酬${rank!.reward}コインを獲得しました。'
        : '8手以内にクリアできませんでした。報酬はありません。';

    return Card(
      color: color.withValues(alpha: 0.25),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isCleared ? Colors.black87 : Colors.red.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(message),
          ],
        ),
      ),
    );
  }
}

class _HintShop extends StatelessWidget {
  final double money;
  final bool enabled;
  final VoidCallback onContains;
  final VoidCallback onPosition;
  final VoidCallback onExclude;
  final VoidCallback onReveal;

  const _HintShop({
    required this.money,
    required this.enabled,
    required this.onContains,
    required this.onPosition,
    required this.onExclude,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ヒントショップ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _HintButton(
              cost: 100,
              label: '数字1つが含まれるか確認',
              money: money,
              enabled: enabled,
              onPressed: onContains,
            ),
            _HintButton(
              cost: 200,
              label: '位置1つの正誤確認',
              money: money,
              enabled: enabled,
              onPressed: onPosition,
            ),
            _HintButton(
              cost: 300,
              label: '使われていない数字を1つ除外',
              money: money,
              enabled: enabled,
              onPressed: onExclude,
            ),
            _HintButton(
              cost: 500,
              label: '1桁だけ開示',
              money: money,
              enabled: enabled,
              onPressed: onReveal,
            ),
          ],
        ),
      ),
    );
  }
}

class _HintAndMissionArea extends StatelessWidget {
  final double money;
  final bool hintsEnabled;
  final List<HintLog> hints;
  final Map<String, bool> missions;
  final VoidCallback onContains;
  final VoidCallback onPosition;
  final VoidCallback onExclude;
  final VoidCallback onReveal;

  const _HintAndMissionArea({
    required this.money,
    required this.hintsEnabled,
    required this.hints,
    required this.missions,
    required this.onContains,
    required this.onPosition,
    required this.onExclude,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hintColumn = _HintColumn(
          money: money,
          enabled: hintsEnabled,
          hints: hints,
          onContains: onContains,
          onPosition: onPosition,
          onExclude: onExclude,
          onReveal: onReveal,
        );
        final missionColumn = _MissionList(missions: missions);

        if (constraints.maxWidth < 620) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [hintColumn, const SizedBox(height: 12), missionColumn],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: hintColumn),
            const SizedBox(width: 12),
            Expanded(child: missionColumn),
          ],
        );
      },
    );
  }
}

class _HintColumn extends StatelessWidget {
  final double money;
  final bool enabled;
  final List<HintLog> hints;
  final VoidCallback onContains;
  final VoidCallback onPosition;
  final VoidCallback onExclude;
  final VoidCallback onReveal;

  const _HintColumn({
    required this.money,
    required this.enabled,
    required this.hints,
    required this.onContains,
    required this.onPosition,
    required this.onExclude,
    required this.onReveal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HintShop(
          money: money,
          enabled: enabled,
          onContains: onContains,
          onPosition: onPosition,
          onExclude: onExclude,
          onReveal: onReveal,
        ),
        const SizedBox(height: 12),
        _HintHistory(hints: hints),
      ],
    );
  }
}

class _HintButton extends StatelessWidget {
  final int cost;
  final String label;
  final double money;
  final bool enabled;
  final VoidCallback onPressed;

  const _HintButton({
    required this.cost,
    required this.label,
    required this.money,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: enabled && money >= cost ? onPressed : null,
        child: Text('$costコイン：$label'),
      ),
    );
  }
}

class _HintHistory extends StatelessWidget {
  final List<HintLog> hints;

  const _HintHistory({required this.hints});

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '購入したヒント',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...hints.map((hint) => Text('${hint.cost}コイン: ${hint.text}')),
          ],
        ),
      ),
    );
  }
}

class _MissionList extends StatelessWidget {
  final Map<String, bool> missions;

  const _MissionList({required this.missions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ミッション',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...missions.entries.map(
              (mission) => CheckboxListTile(
                value: mission.value,
                onChanged: null,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(mission.key),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<GuessResult> history;

  const _HistoryList({required this.history});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '入力履歴',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'まだ回答はありません',
                  style: TextStyle(color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: 210,
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final result = history[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: index == 0
                            ? Colors.yellow.shade100
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.guess,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 5,
                              ),
                            ),
                          ),
                          Text(
                            '${result.hit} Hit / ${result.blow} Blow',
                            style: TextStyle(
                              color: Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
