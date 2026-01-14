import 'package:flutter/material.dart';
import 'package:flutter2025_numberguessinggame/HighLowDifficultyPage.dart';
import 'HitAndBlowDifficultyPage.dart';

class GameSelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("ゲーム選択"),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.show_chart), text: "High & Low"),
              Tab(icon: Icon(Icons.grid_3x3), text: "Hit & Blow"),
            ],
          ),
        ),
        body: TabBarView(
          children: [HighLowDifficultyPage(), HitAndBlowDifficultyPage()],
        ),
      ),
    );
  }
}
