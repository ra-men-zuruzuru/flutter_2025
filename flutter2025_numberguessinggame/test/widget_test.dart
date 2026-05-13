import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter2025_numberguessinggame/main.dart';

void main() {
  testWidgets('shows game selection tabs and High & Low start screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('High & Low'), findsWidgets);
    expect(find.text('Hit & Blow'), findsOneWidget);
    expect(find.text('ゲーム開始'), findsOneWidget);
    expect(find.byIcon(Icons.show_chart), findsWidgets);
  });

  testWidgets('asks for confirmation before leaving High & Low', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('ゲーム開始'));
    await tester.pumpAndSettle();

    expect(find.text('持ち金: 100'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('メニューに戻りますか？'), findsOneWidget);

    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('持ち金: 100'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();

    expect(find.text('ゲーム開始'), findsOneWidget);
  });
}
