import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/tournament_repository.dart';
import '../theme/app_theme.dart';
import '../widget_bridge/home_widget_bridge.dart';
import '../widgets/aurora_background.dart';
import '../widgets/segmented_tabs.dart';
import 'bracket/bracket_view.dart';
import 'groups/groups_view.dart';
import 'scorers/scorers_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.repository, this.notice});

  final TournamentRepository repository;

  /// Optional slim banner shown under the tabs — e.g. when the live feed
  /// failed and the app fell back to illustrative data.
  final String? notice;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  bool _refreshing = false;

  static const _labels = ['Eliminatórias', 'Classificação', 'Artilheiros'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  /// Re-pulls the tournament snapshot when the user comes back to the
  /// app, so scores/standings don't stay frozen at launch-time values —
  /// then mirrors the fresh data to the Home Screen widget (WidgetKit's
  /// own refresh budget is scarce; a foreground push is the most
  /// reliable way to keep it current).
  Future<void> _refreshData() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await widget.repository.refresh();
      if (mounted) setState(() {});
    } catch (_) {
      // Keep showing the last good snapshot; next resume retries.
    } finally {
      _refreshing = false;
      HomeWidgetBridge.pushSnapshot(widget.repository);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0x00000000),
      child: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(),
                    const SizedBox(height: 13),
                    SegmentedTabs(
                      labels: _labels,
                      selectedIndex: _tab,
                      onChanged: (i) {
                        if (i == _tab) return;
                        HapticFeedback.selectionClick();
                        setState(() => _tab = i);
                      },
                    ),
                    if (widget.notice != null) ...[
                      const SizedBox(height: 10),
                      _NoticeBanner(text: widget.notice!),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.02),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: switch (_tab) {
                    0 => BracketView(
                        key: const ValueKey('elim'),
                        repository: widget.repository,
                      ),
                    1 => GroupsView(
                        key: const ValueKey('grupos'),
                        repository: widget.repository,
                      ),
                    _ => ScorersView(
                        key: const ValueKey('artilheiros'),
                        repository: widget.repository,
                      ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small "v1.2.3 (4)" tag in the header, so feedback and bug reports can
/// name the exact SemVer build they came from.
class _VersionTag extends StatelessWidget {
  const _VersionTag();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();
        return Text(
          'v${info.version} (${info.buildNumber})',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.ink.withValues(alpha: 0.35),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.draw.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.draw.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🏆', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 7),
            const Text('MUNDIAL 2026', style: AppTextStyles.eyebrow),
            const SizedBox(width: 7),
            Text('·', style: TextStyle(color: AppColors.ink.withValues(alpha: 0.32), fontSize: 11)),
            const SizedBox(width: 7),
            const Text('🇺🇸 🇨🇦 🇲🇽', style: TextStyle(fontSize: 11, letterSpacing: 0.6)),
            const Spacer(),
            const _VersionTag(),
          ],
        ),
        const SizedBox(height: 5),
        // Brand name is deliberately generic ("Mundial 2026"): FIFA
        // aggressively enforces its marks ("FIFA", "World Cup", "Copa do
        // Mundo 2026") and App Review rejects on 5.2.1 for using them.
        const Text('Mundial 2026', style: AppTextStyles.title),
      ],
    );
  }
}
