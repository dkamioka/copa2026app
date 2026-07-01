import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'data/api_football/api_config.dart';
import 'data/api_football/api_football_repository.dart';
import 'data/mock_tournament_repository.dart';
import 'data/tournament_repository.dart';
import 'screens/home_shell.dart';
import 'widget_bridge/home_widget_bridge.dart';
import 'widgets/aurora_background.dart';

const CupertinoThemeData kAppTheme = CupertinoThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFFE11D6B),
  scaffoldBackgroundColor: Color(0xFFEEF1F7),
  textTheme: CupertinoTextThemeData(
    textStyle: TextStyle(fontFamily: '.SF Pro Text', color: Color(0xFF16162E)),
  ),
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const AppBootstrap());
}

/// Result of resolving which data source the app should run on.
class _Bootstrapped {
  final TournamentRepository repository;
  final String? notice;
  _Bootstrapped(this.repository, this.notice);
}

/// Decides the data source at startup: the live API-Football repository
/// when a key is configured (falling back to the offline mock if the
/// initial load fails), or the mock directly when no key is present.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final Future<_Bootstrapped> _future = _bootstrap();

  Future<_Bootstrapped> _bootstrap() async {
    if (ApiConfig.useMock) {
      final repo = MockTournamentRepository();
      await repo.refresh();
      HomeWidgetBridge.pushSnapshot(repo);
      return _Bootstrapped(repo, null);
    }

    final api = ApiFootballRepository();
    try {
      await api.refresh();
      HomeWidgetBridge.pushSnapshot(api);
      return _Bootstrapped(api, null);
    } catch (_) {
      // Live feed unavailable (no network, quota, bad key…) — degrade to
      // the illustrative dataset rather than showing an empty app.
      final repo = MockTournamentRepository();
      await repo.refresh();
      HomeWidgetBridge.pushSnapshot(repo);
      return _Bootstrapped(
        repo,
        'Sem conexão com os dados ao vivo — exibindo dados de exemplo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Copa do Mundo 2026',
      debugShowCheckedModeBanner: false,
      theme: kAppTheme,
      home: FutureBuilder<_Bootstrapped>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const _LoadingScreen();
          final data = snapshot.data!;
          return HomeShell(repository: data.repository, notice: data.notice);
        },
      ),
    );
  }
}

/// Simple app entry used by tests, which inject a ready repository and
/// skip the async bootstrap entirely.
class WorldCup2026App extends StatelessWidget {
  const WorldCup2026App({super.key, required this.repository});

  final TournamentRepository repository;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Copa do Mundo 2026',
      debugShowCheckedModeBanner: false,
      theme: kAppTheme,
      home: HomeShell(repository: repository),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: AuroraBackground(
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🏆', style: TextStyle(fontSize: 44)),
              SizedBox(height: 16),
              Text(
                'Copa do Mundo 2026',
                style: TextStyle(
                  fontFamily: '.SF Pro Display',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF16162E),
                ),
              ),
              SizedBox(height: 16),
              CupertinoActivityIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
