import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'HighLowRankingService.dart';

enum HighLowPhase { betting, guessing, roundResult, gameOver }

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
  XFile? _avatar;
  HighLowPhase _phase = HighLowPhase.betting;
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
        _message = '予想は数字で入力してください。';
      });
      return;
    }

    if (guess < 1 || guess > rule.maxNumber) {
      setState(() {
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
        _lastResult =
            '正解！ $_missesミスで$multiplier倍、${_formatMoney(reward)}を獲得しました。';
        _message = '続けるか、ここで降りるか選んでください。';
        _guessController.clear();
      });
      return;
    }

    setState(() {
      _misses++;
      _guessController.clear();

      if (_misses >= rule.maxMisses) {
        _money -= _bet;
        _phase = _money <= 0 ? HighLowPhase.gameOver : HighLowPhase.roundResult;
        _lastResult = '失敗... 答えは$_targetNumberでした。掛け金$_betを失いました。';
        _message = _money <= 0 ? '持ち金がなくなりました。' : '続けるか、ここで降りるか選んでください。';
      } else if (guess < _targetNumber) {
        _message = 'もっと大きい数字です。';
      } else {
        _message = 'もっと小さい数字です。';
      }
    });
  }

  void _continueGame() {
    setState(() {
      _roundNumber++;
      _bet = 0;
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
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _scoreSubmitMessage = '投稿に失敗しました。通信状態やSupabase設定を確認してください。';
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
                _StatusPanel(
                  money: _formatMoney(_money),
                  roundNumber: _roundNumber,
                  rule: rule,
                  bet: _bet,
                  misses: _misses,
                  remainingMisses: remainingMisses,
                ),
                const SizedBox(height: 20),
                Text(
                  _message,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_lastResult.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _lastResult,
                    style: const TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
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
  final String money;
  final int roundNumber;
  final HighLowRoundRule rule;
  final int bet;
  final int misses;
  final int remainingMisses;

  const _StatusPanel({
    required this.money,
    required this.roundNumber,
    required this.rule,
    required this.bet,
    required this.misses,
    required this.remainingMisses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '持ち金: $money',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _StatusChip(label: 'ラウンド', value: '$roundNumber'),
                _StatusChip(label: '条件', value: rule.name),
                _StatusChip(label: '範囲', value: '1〜${rule.maxNumber}'),
                _StatusChip(label: '掛け金', value: bet == 0 ? '-' : '$bet'),
                _StatusChip(label: 'ミス', value: '$misses'),
                _StatusChip(label: '失敗まで', value: '$remainingMisses回'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '倍率: ${rule.multipliers.asMap().entries.map((entry) => '${entry.key}ミス=${entry.value}倍').join(' / ')}',
              style: TextStyle(color: Colors.grey.shade700),
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

  const _StatusChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.grey.shade100,
    );
  }
}
