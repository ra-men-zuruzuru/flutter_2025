import 'package:flutter/material.dart';
import 'dart:math';
import 'hit_and_blow_difficulty.dart';

class HitAndBlowGamePage extends StatefulWidget {
  @override
  _HitAndBlowGamePageState createState() => _HitAndBlowGamePageState();
}

class GuessResult {
  final String guess;
  final int hit;
  final int blow;

  GuessResult({required this.guess, required this.hit, required this.blow});
}

class _HitAndBlowGamePageState extends State<HitAndBlowGamePage> {
  HitAndBlowDifficulty? _difficulty;
  List<int> _targetNumbers = [];
  List<GuessResult> _history = [];
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _errorMessage = '';
  bool _isGameOver = false;

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is HitAndBlowDifficulty) {
        _difficulty = args;
        _startNewGame();
      }
      _isInitialized = true;
    }
  }

  void _startNewGame() {
    if (_difficulty == null) return;
    setState(() {
      _targetNumbers = _generateUniqueNumbers(_difficulty!.digits);
      _history.clear();
      _controller.clear();
      _errorMessage = '';
      _isGameOver = false;
    });
    print("Target: $_targetNumbers"); // Debug
  }

  List<int> _generateUniqueNumbers(int count) {
    var list = List.generate(10, (i) => i);
    list.shuffle();
    return list.sublist(0, count);
  }

  void _checkGuess() {
    setState(() {
      _errorMessage = '';
    });

    final input = _controller.text;

    // Validation
    if (input.length != _difficulty!.digits) {
      setState(() {
        _errorMessage = '${_difficulty!.digits}桁の数字を入力してください';
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

    // Logic
    final guessDigits = input.split('').map(int.parse).toList();
    int hit = 0;
    int blow = 0;

    for (int i = 0; i < guessDigits.length; i++) {
      if (guessDigits[i] == _targetNumbers[i]) {
        hit++;
      } else if (_targetNumbers.contains(guessDigits[i])) {
        blow++;
      }
    }

    setState(() {
      _history.insert(0, GuessResult(guess: input, hit: hit, blow: blow));
      _controller.clear();

      // Keep focus on input field
      _focusNode.requestFocus();

      if (hit == _difficulty!.digits) {
        _isGameOver = true;
        _showWinDialog();
      }
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("正解！"),
        content: Text("おめでとうございます！\n${_history.length}回で正解しました！"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: Text("もう一度"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("戻る"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_difficulty == null)
      return Scaffold(appBar: AppBar(title: Text("Error")));

    return Scaffold(
      appBar: AppBar(title: Text("Hit & Blow - ${_difficulty!.digits}桁")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "数字が重複しない${_difficulty!.digits}桁の数字を当ててね",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    keyboardType: TextInputType.number,
                    maxLength: _difficulty!.digits,
                    decoration: InputDecoration(
                      labelText: '数字を入力',
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                    onSubmitted: (_) => _isGameOver ? null : _checkGuess(),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isGameOver ? null : _checkGuess,
                  child: Text("判定"),
                ),
              ],
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ),
            Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final result = _history[index];
                  return Card(
                    color: index == 0 ? Colors.yellow.shade100 : null,
                    child: ListTile(
                      title: Text(
                        result.guess,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 5,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${result.hit} Hit (場所も数字も合ってる！)",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${result.blow} Blow (数字は合ってるけど場所が違う)",
                            style: TextStyle(color: Colors.blue),
                          ),
                        ],
                      ),
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
