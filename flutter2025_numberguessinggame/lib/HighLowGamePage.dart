import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'HighLowRankingService.dart';

enum HighLowPhase { betting, guessing, roundResult, gameOver }

enum GuessHintType { none, tooHigh, tooLow }

enum RoundFeedbackType { none, win, lose }

class HighLowRoundRule {
  final String name;
  final int maxNumber;
  final List<double> multipliers;
  final Color color;

  const HighLowRoundRule({
    required this.name,
    required this.maxNumber,
    required this.multipliers,
    required this.color,
  });

  int get maxMisses => multipliers.length - 1;

  double multiplierForMisses(int misses) => multipliers[misses];
}

class HighLowGamePage extends StatefulWidget {
  const HighLowGamePage({super.key});

  @override
  State<HighLowGamePage> createState() => _HighLowGamePageState();
}

class _HighLowGamePageState extends State<HighLowGamePage> {
  static const double _initialMoney = 100;

  final Random _random = Random();
  final TextEditingController _betController = TextEditingController();
  final TextEditingController _guessController = TextEditingController();
  final TextEditingController _handleNameController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  HighLowRankingService? _rankingService;

  double _money = _initialMoney;
  int _roundNumber = 1;
  int _bet = 0;
  int _misses = 0;
  int _targetNumber = 0;
  int? _lastGuess;
  XFile? _avatar;
  HighLowPhase _phase = HighLowPhase.betting;
  GuessHintType _hintType = GuessHintType.none;
  RoundFeedbackType _feedbackType = RoundFeedbackType.none;
  bool _allowMenuReturn = false;
  bool _isSubmittingScore = false;
  bool _scoreSubmitted = false;
  String _message = '掛け金を決めてください。';
  String _lastResult = '';
  String _scoreSubmitMessage = '';

  HighLowRankingService get _service {
    return _rankingService ??= HighLowRankingService();
  }

  HighLowRoundRule get _currentRule {
    if (_roundNumber <= 3) {
      return const HighLowRoundRule(
        name: 'かんたん',
        maxNumber: 10,
        multipliers: [1.5, 1.2, 1.1, 1, 0],
        color: Color(0xFF4CAF50),
      );
    }

    if (_roundNumber <= 8) {
      return const HighLowRoundRule(
        name: 'ふつう',
        maxNumber: 50,
        multipliers: [3, 2.5, 2, 1.7, 1.3, 1, 0],
        color: Color(0xFF2196F3),
      );
    }

    return const HighLowRoundRule(
      name: 'むずかしい',
      maxNumber: 100,
      multipliers: [5, 4.5, 4, 3.5, 3, 2.5, 2, 1, 0],
      color: Color(0xFFF44336),
    );
  }

  String _formatMoney(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  void _startRound() {
    final bet = int.tryParse(_betController.text);

    if (bet == null) {
      setState(() {
        _message = '掛け金は数字で入力してください。';
      });
      return;
    }

    if (bet < 1 || bet > _money) {
      setState(() {
        _message = '掛け金は1から現在の持ち金までで入力してください。';
      });
      return;
    }

    setState(() {
      _bet = bet;
      _misses = 0;
      _targetNumber = _random.nextInt(_currentRule.maxNumber) + 1;
      _lastGuess = null;
      _hintType = GuessHintType.none;
      _feedbackType = RoundFeedbackType.none;
      _phase = HighLowPhase.guessing;
      _message = '1〜${_currentRule.maxNumber}の数字を当ててください。';
      _lastResult = '';
      _guessController.clear();
    });
  }

  void _checkGuess() {
    final rule = _currentRule;
    final guess = int.tryParse(_guessController.text);

    if (guess == null) {
      setState(() {
        _hintType = GuessHintType.none;
        _feedbackType = RoundFeedbackType.none;
        _message = '予想は数字で入力してください。';
      });
      return;
    }

    if (guess < 1 || guess > rule.maxNumber) {
      setState(() {
        _hintType = GuessHintType.none;
        _feedbackType = RoundFeedbackType.none;
        _message = '1〜${rule.maxNumber}の範囲で入力してください。';
      });
      return;
    }

    if (guess == _targetNumber) {
      final multiplier = rule.multiplierForMisses(_misses);
      final reward = _bet * multiplier;

      setState(() {
        _money += reward;
        _phase = HighLowPhase.roundResult;
        _lastGuess = guess;
        _hintType = GuessHintType.none;
        _feedbackType = RoundFeedbackType.win;
        _lastResult =
            '正解！ $_missesミスで$multiplier倍、${_formatMoney(reward)}を獲得しました。';
        _message = '続けるか、ここで降りるか選んでください。';
        _guessController.clear();
      });
      return;
    }

    setState(() {
      _misses++;
      _lastGuess = guess;
      _guessController.clear();

      if (_misses >= rule.maxMisses) {
        _money -= _bet;
        _phase = _money <= 0 ? HighLowPhase.gameOver : HighLowPhase.roundResult;
        _hintType = GuessHintType.none;
        _feedbackType = RoundFeedbackType.lose;
        _lastResult = '失敗... 答えは$_targetNumberでした。掛け金$_betを失いました。';
        _message = _money <= 0 ? '持ち金がなくなりました。' : '続けるか、ここで降りるか選んでください。';
      } else if (guess < _targetNumber) {
        _hintType = GuessHintType.tooLow;
        _feedbackType = RoundFeedbackType.none;
        _message = 'もっと大きい数字です。';
      } else {
        _hintType = GuessHintType.tooHigh;
        _feedbackType = RoundFeedbackType.none;
        _message = 'もっと小さい数字です。';
      }
    });
  }

  void _continueGame() {
    setState(() {
      _roundNumber++;
      _bet = 0;
      _lastGuess = null;
      _hintType = GuessHintType.none;
      _feedbackType = RoundFeedbackType.none;
      _phase = HighLowPhase.betting;
      _message = '次の掛け金を決めてください。';
      _lastResult = '';
      _betController.clear();
      _guessController.clear();
    });
  }

  void _retire() {
    setState(() {
      _phase = HighLowPhase.gameOver;
      _hintType = GuessHintType.none;
      _feedbackType = RoundFeedbackType.none;
      _scoreSubmitted = false;
      _isSubmittingScore = false;
      _scoreSubmitMessage = '';
      _message = 'ゲームを降りました。';
      _lastResult = '最終スコアは${_formatMoney(_money)}です。';
    });
  }

  void _restart() {
    setState(() {
      _money = _initialMoney;
      _roundNumber = 1;
      _bet = 0;
      _misses = 0;
      _targetNumber = 0;
      _lastGuess = null;
      _hintType = GuessHintType.none;
      _feedbackType = RoundFeedbackType.none;
      _phase = HighLowPhase.betting;
      _scoreSubmitted = false;
      _isSubmittingScore = false;
      _scoreSubmitMessage = '';
      _message = '掛け金を決めてください。';
      _lastResult = '';
      _betController.clear();
      _guessController.clear();
    });
  }

  Future<void> _pickAvatar() async {
    final pickedAvatar = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      imageQuality: 80,
    );

    if (pickedAvatar == null || !mounted) {
      return;
    }

    setState(() {
      _avatar = pickedAvatar;
      _scoreSubmitMessage = '';
    });
  }

  Future<void> _submitScore() async {
    final handleName = _handleNameController.text.trim();

    if (handleName.isEmpty) {
      setState(() {
        _scoreSubmitMessage = 'ハンドルネームを入力してください。';
      });
      return;
    }

    if (handleName.length > 20) {
      setState(() {
        _scoreSubmitMessage = 'ハンドルネームは20文字以内で入力してください。';
      });
      return;
    }

    setState(() {
      _isSubmittingScore = true;
      _scoreSubmitMessage = '';
    });

    try {
      String? avatarPath;
      if (_avatar != null) {
        avatarPath = await _service.uploadAvatar(_avatar!);
      }

      await _service.submitScore(
        handleName: handleName,
        score: _money,
        avatarPath: avatarPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _scoreSubmitted = true;
        _scoreSubmitMessage = 'ランキングに投稿しました。';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _scoreSubmitMessage = '投稿に失敗しました: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingScore = false;
        });
      }
    }
  }

  Future<void> _confirmReturnToMenu() async {
    final shouldReturn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メニューに戻りますか？'),
        content: const Text('現在のHigh & Lowの進行状況は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('戻る'),
          ),
        ],
      ),
    );

    if (!mounted || shouldReturn != true) {
      return;
    }

    setState(() {
      _allowMenuReturn = true;
    });
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _betController.dispose();
    _guessController.dispose();
    _handleNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rule = _currentRule;
    final remainingMisses = rule.maxMisses - _misses;

    return PopScope(
      canPop: _allowMenuReturn,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        _confirmReturnToMenu();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('High & Low'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _confirmReturnToMenu,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusPanel(roundNumber: _roundNumber, rule: rule),
                const SizedBox(height: 8),
                _MultiplierStrip(rule: rule),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MoneyPiggyBank(
                      money: _money,
                      formattedMoney: _formatMoney(_money),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _MiddleFeedbackArea(
                        message: _message,
                        lastResult: _lastResult,
                        lastGuess: _lastGuess,
                        hintType: _hintType,
                        feedbackType: _feedbackType,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_phase != HighLowPhase.gameOver)
                  _RoundInfoStrip(
                    bet: _bet,
                    misses: _misses,
                    remainingMisses: remainingMisses,
                  ),
                const SizedBox(height: 24),
                if (_phase == HighLowPhase.betting) _buildBetForm(),
                if (_phase == HighLowPhase.guessing) _buildGuessForm(rule),
                if (_phase == HighLowPhase.roundResult) _buildResultActions(),
                if (_phase == HighLowPhase.gameOver) _buildGameOverActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBetForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _betController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: '掛け金',
          ),
          onSubmitted: (_) => _startRound(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _startRound, child: const Text('ラウンド開始')),
      ],
    );
  }

  Widget _buildGuessForm(HighLowRoundRule rule) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _guessController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: '1〜${rule.maxNumber}の数字',
          ),
          onSubmitted: (_) => _checkGuess(),
        ),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: _checkGuess, child: const Text('判定')),
      ],
    );
  }

  Widget _buildResultActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(onPressed: _retire, child: const Text('降りる')),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _continueGame,
            child: const Text('続ける'),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'スコア: ${_formatMoney(_money)}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _ScoreSubmitPanel(
          avatar: _avatar,
          handleNameController: _handleNameController,
          message: _scoreSubmitMessage,
          isSubmitting: _isSubmittingScore,
          isSubmitted: _scoreSubmitted,
          onPickAvatar: _pickAvatar,
          onSubmit: _submitScore,
          onShowRanking: () {
            Navigator.pushNamed(context, '/high_low_ranking');
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _restart, child: const Text('もう一度遊ぶ')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}

class _ScoreSubmitPanel extends StatelessWidget {
  final XFile? avatar;
  final TextEditingController handleNameController;
  final String message;
  final bool isSubmitting;
  final bool isSubmitted;
  final VoidCallback onPickAvatar;
  final VoidCallback onSubmit;
  final VoidCallback onShowRanking;

  const _ScoreSubmitPanel({
    required this.avatar,
    required this.handleNameController,
    required this.message,
    required this.isSubmitting,
    required this.isSubmitted,
    required this.onPickAvatar,
    required this.onSubmit,
    required this.onShowRanking,
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
              'ランキングに投稿',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _SelectedAvatar(avatar: avatar),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isSubmitting || isSubmitted
                        ? null
                        : onPickAvatar,
                    icon: const Icon(Icons.image),
                    label: const Text('アバターを選ぶ'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: handleNameController,
              enabled: !isSubmitting && !isSubmitted,
              maxLength: 20,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'ハンドルネーム',
                counterText: '',
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: TextStyle(
                  color: isSubmitted ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isSubmitting || isSubmitted ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(isSubmitted ? '投稿済み' : 'スコアを投稿'),
            ),
            TextButton.icon(
              onPressed: onShowRanking,
              icon: const Icon(Icons.emoji_events),
              label: const Text('ランキングを見る'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedAvatar extends StatelessWidget {
  final XFile? avatar;

  const _SelectedAvatar({required this.avatar});

  @override
  Widget build(BuildContext context) {
    if (avatar == null) {
      return const CircleAvatar(radius: 28, child: Icon(Icons.person));
    }

    return FutureBuilder<Uint8List>(
      future: avatar!.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircleAvatar(
            radius: 28,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return CircleAvatar(
          radius: 28,
          backgroundImage: MemoryImage(snapshot.data!),
        );
      },
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final int roundNumber;
  final HighLowRoundRule rule;

  const _StatusPanel({required this.roundNumber, required this.rule});

  @override
  Widget build(BuildContext context) {
    final phaseColor = switch (rule.name) {
      'かんたん' => const Color(0xFFD7F5D6),
      'ふつう' => const Color(0xFFFFF3BF),
      _ => const Color(0xFFFFD6D6),
    };

    return Card(
      color: const Color(0xFFE8E8E8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(
              'ROUND：$roundNumber',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Flexible(
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  _StatusChip(
                    label: 'フェーズ',
                    value: rule.name,
                    backgroundColor: phaseColor,
                    borderColor: Colors.black45,
                  ),
                  _StatusChip(
                    label: '範囲',
                    value: '1〜${rule.maxNumber}',
                    backgroundColor: Colors.white,
                    borderColor: Colors.black45,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color backgroundColor;
  final Color borderColor;

  const _StatusChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _MultiplierStrip extends StatelessWidget {
  final HighLowRoundRule rule;

  const _MultiplierStrip({required this.rule});

  @override
  Widget build(BuildContext context) {
    return Text(
      '倍率　${rule.multipliers.asMap().entries.map((entry) => '${entry.key}ミス=${entry.value}倍').join(' / ')}',
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _MoneyPiggyBank extends StatelessWidget {
  final double money;
  final String formattedMoney;

  const _MoneyPiggyBank({required this.money, required this.formattedMoney});

  @override
  Widget build(BuildContext context) {
    final tier = _PiggyTier.fromMoney(money);

    return SizedBox(
      width: 96,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) {
              final scale = Tween<double>(begin: 0.86, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              );
              return ScaleTransition(scale: scale, child: child);
            },
            child: AnimatedScale(
              key: ValueKey('${tier.label}-$formattedMoney'),
              scale: tier.scale,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.savings, size: 64, color: tier.color),
                  if (tier.showSparkle)
                    const Positioned(
                      right: 8,
                      top: 4,
                      child: Icon(
                        Icons.star,
                        color: Color(0xFFFFC400),
                        size: 20,
                      ),
                    ),
                  if (money <= 0)
                    const Positioned(
                      right: 8,
                      bottom: 6,
                      child: Icon(
                        Icons.remove_circle,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '持ち金',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            formattedMoney,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _PiggyTier {
  final String label;
  final Color color;
  final double scale;
  final bool showSparkle;

  const _PiggyTier({
    required this.label,
    required this.color,
    required this.scale,
    required this.showSparkle,
  });

  factory _PiggyTier.fromMoney(double money) {
    if (money <= 0) {
      return const _PiggyTier(
        label: 'empty',
        color: Colors.grey,
        scale: 0.92,
        showSparkle: false,
      );
    }
    if (money < 100) {
      return const _PiggyTier(
        label: 'low',
        color: Color(0xFFF8BBD0),
        scale: 0.95,
        showSparkle: false,
      );
    }
    if (money < 200) {
      return const _PiggyTier(
        label: 'normal',
        color: Color(0xFFF48FB1),
        scale: 1,
        showSparkle: false,
      );
    }
    if (money < 500) {
      return const _PiggyTier(
        label: 'high',
        color: Color(0xFFFF6FAE),
        scale: 1.08,
        showSparkle: false,
      );
    }
    return const _PiggyTier(
      label: 'rich',
      color: Color(0xFFFFB74D),
      scale: 1.14,
      showSparkle: true,
    );
  }
}

class _MiddleFeedbackArea extends StatelessWidget {
  final String message;
  final String lastResult;
  final int? lastGuess;
  final GuessHintType hintType;
  final RoundFeedbackType feedbackType;

  const _MiddleFeedbackArea({
    required this.message,
    required this.lastResult,
    required this.lastGuess,
    required this.hintType,
    required this.feedbackType,
  });

  @override
  Widget build(BuildContext context) {
    if (feedbackType != RoundFeedbackType.none) {
      return _RoundFeedbackBanner(type: feedbackType, text: lastResult);
    }

    if (hintType != GuessHintType.none && lastGuess != null) {
      return _GuessHint(lastGuess: lastGuess!, hintType: hintType);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        if (lastResult.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(lastResult, style: const TextStyle(fontSize: 16)),
        ],
      ],
    );
  }
}

class _GuessHint extends StatelessWidget {
  final int lastGuess;
  final GuessHintType hintType;

  const _GuessHint({required this.lastGuess, required this.hintType});

  @override
  Widget build(BuildContext context) {
    final isTooHigh = hintType == GuessHintType.tooHigh;
    final color = isTooHigh ? Colors.red : Colors.blue;
    final answerHint = isTooHigh ? '答えはもっと小さいです。' : '答えはもっと大きいです。';

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 20, color: Colors.black),
        children: [
          const TextSpan(text: 'あなたが入力したのは　'),
          TextSpan(
            text: '$lastGuess　$answerHint',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RoundFeedbackBanner extends StatelessWidget {
  final RoundFeedbackType type;
  final String text;

  const _RoundFeedbackBanner({required this.type, required this.text});

  @override
  Widget build(BuildContext context) {
    final isWin = type == RoundFeedbackType.win;
    final color = isWin ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final backgroundColor = isWin
        ? const Color(0xFFE8F5E9)
        : const Color(0xFFFFEBEE);
    final icon = isWin ? Icons.celebration : Icons.warning_amber;
    final title = isWin ? '成功！' : '失敗...';

    return TweenAnimationBuilder<double>(
      key: ValueKey('$type-$text'),
      tween: Tween<double>(begin: isWin ? 0.88 : -0.03, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: isWin ? Curves.easeOutBack : Curves.elasticOut,
      builder: (context, value, child) {
        if (isWin) {
          return Transform.scale(scale: value, child: child);
        }
        return Transform.translate(
          offset: Offset((value - 1) * 32, 0),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(text, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundInfoStrip extends StatelessWidget {
  final int bet;
  final int misses;
  final int remainingMisses;

  const _RoundInfoStrip({
    required this.bet,
    required this.misses,
    required this.remainingMisses,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _InfoPill(label: '掛け金', value: bet == 0 ? '-' : '$bet'),
        _InfoPill(label: 'ミス', value: '$misses'),
        _InfoPill(label: '失敗まで', value: '$remainingMisses回'),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        '$label：$value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
