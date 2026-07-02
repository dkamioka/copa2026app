import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:worldcup2026/data/mock_tournament_repository.dart';
import 'package:worldcup2026/main.dart';
import 'package:worldcup2026/widgets/segmented_tabs.dart';

// The aurora background and live-match pulse dot animate continuously by
// design, so `pumpAndSettle` never settles here — use bounded pumps instead.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Mundial 2026',
      packageName: 'com.veogroup.worldcup2026',
      version: '1.3.0',
      buildNumber: '5',
      buildSignature: '',
    );
  });
  testWidgets('App loads the bracket tab with a live match banner', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    expect(find.textContaining('Mundial 2026'), findsOneWidget);
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

  testWidgets('Dragging the sheet handle down dismisses the detail sheet', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    await tester.tap(find.text('Brasil').first);
    await _settle(tester);
    expect(find.text('LANCES DO JOGO'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('sheet_drag_handle')), const Offset(0, 400));
    await _settle(tester);
    await _settle(tester);

    expect(find.text('LANCES DO JOGO'), findsNothing);
  });

  testWidgets('Segmented tabs meet the 44pt minimum touch target', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    final barSize = tester.getSize(find.byType(SegmentedTabs));
    expect(barSize.height, greaterThanOrEqualTo(44));
  });

  testWidgets('Running version is visible in the header', (WidgetTester tester) async {
    await tester.pumpWidget(WorldCup2026App(repository: MockTournamentRepository()));
    await _settle(tester);

    expect(find.text('v1.3.0 (5)'), findsOneWidget);
  });
}
