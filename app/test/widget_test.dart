import 'package:flutter_test/flutter_test.dart';

import 'package:worldcup2026/data/mock_tournament_repository.dart';
import 'package:worldcup2026/main.dart';

// The aurora background and live-match pulse dot animate continuously by
// design, so `pumpAndSettle` never settles here — use bounded pumps instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('App loads the bracket tab with a live match banner', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    expect(find.textContaining('Copa do Mundo 2026'), findsOneWidget);
    expect(find.text('Chave'), findsOneWidget);
    expect(find.text('AO VIVO'), findsOneWidget);
  });

  testWidgets('Switching tabs shows group standings and scorers', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    await tester.tap(find.text('Classificação'));
    await _settle(tester);
    expect(find.text('Fase de Grupos'), findsOneWidget);

    await tester.tap(find.text('Artilheiros'));
    await _settle(tester);
    expect(find.text('Artilheiros'), findsWidgets);
  });

  testWidgets('Tapping a finished match opens the detail sheet', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    await tester.tap(find.text('Brasil').first);
    await _settle(tester);

    expect(find.text('LANCES DO JOGO'), findsOneWidget);
  });
}
