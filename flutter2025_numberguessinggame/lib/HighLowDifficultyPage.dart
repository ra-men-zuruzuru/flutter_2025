import 'package:flutter/material.dart';
import 'difficulty.dart';

class HighLowDifficultyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Remove Scaffold to fit in TabBarView
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: Difficulty.values.map((difficulty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: 200,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: difficulty.color,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, "/game", arguments: difficulty);
                },
                child: Text(difficulty.name),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
