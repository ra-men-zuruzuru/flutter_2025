import 'package:flutter/material.dart';
import 'dart:math';
import 'difficulty.dart';

class HighLowGamePage extends StatefulWidget {
  @override
  _HighLowGamePageState createState() => _HighLowGamePageState();
}

class _HighLowGamePageState extends State<HighLowGamePage> {
  Difficulty? _difficulty;
  int? _targetNumber;
  int _remainingAttempts = 0;
  String _feedbackMessage = '';
  final TextEditingController _controller = TextEditingController();

  // Initialize state after the widget is built and arguments are available?
  // Actually, arguments are available via context in build, or we can use didChangeDependencies
  // But standard way for simple arguments passing via pushNamed is often reading in build or didChangeDependencies.
  // To initialize logic "once", we can do it in didChangeDependencies.

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Difficulty) {
        _difficulty = args;
        _startNewGame();
      }
      _isInitialized = true;
    }
  }

  void _startNewGame() {
    if (_difficulty == null) return;
    setState(() {
      _targetNumber = Random().nextInt(_difficulty!.maxNumber) + 1;
      _remainingAttempts = _difficulty!.attempts;
      _feedbackMessage = '数字を入力してね！';
      _controller.clear();
    });
    print("Target: $_targetNumber"); // For debugging
  }

  void _checkGuess() {
    if (_controller.text.isEmpty) return;
    final int? guess = int.tryParse(_controller.text);

    if (guess == null) {
      setState(() {
        _feedbackMessage = '数字を入力してください';
      });
      return;
    }

    setState(() {
      _remainingAttempts--;
      if (guess == _targetNumber) {
        _feedbackMessage = '正解！おめでとう！';
        _showGameOverDialog(true);
      } else if (_remainingAttempts <= 0) {
        _feedbackMessage = '残念... ゲームオーバー';
        _showGameOverDialog(false);
      } else if (guess < _targetNumber!) {
        _feedbackMessage = 'もっと大きいよ！';
      } else {
        _feedbackMessage = 'もっと小さいよ！';
      }
      _controller.clear();
    });
  }

  void _showGameOverDialog(bool isWin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isWin ? "正解！" : "ゲームオーバー"),
          content: Text(
            isWin
                ? "素晴らしい！答えは $_targetNumber でした。"
                : "残念... 答えは $_targetNumber でした。",
          ),
          actions: <Widget>[
            TextButton(
              child: Text("もう一度"),
              onPressed: () {
                Navigator.of(context).pop();
                _startNewGame();
              },
            ),
            TextButton(
              child: Text("戻る"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to Home
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If difficulty didn't load correctly (should rarely happen if navigated correctly)
    if (_difficulty == null) {
      // Fallback or loading
      return Scaffold(appBar: AppBar(title: Text("Error")));
    }

    return Scaffold(
      appBar: AppBar(title: Text("数あてゲーム (${_difficulty!.name})")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              "残り回数: $_remainingAttempts",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              "1 ～ ${_difficulty!.maxNumber} の数字を当ててね",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            Text(
              _feedbackMessage,
              style: TextStyle(fontSize: 24, color: Colors.blueAccent),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: '数字を入力',
              ),
              onSubmitted: (_) => _checkGuess(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _remainingAttempts > 0 && _feedbackMessage != '正解！おめでとう！'
                  ? _checkGuess
                  : null,
              child: Text("判定"),
            ),
          ],
        ),
      ),
    );
  }
}
