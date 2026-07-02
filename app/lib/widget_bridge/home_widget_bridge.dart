import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/tournament_repository.dart';
import '../models/match.dart';

/// Pushes a compact JSON snapshot of the tournament to the native iOS
/// Home Screen widget extension via an App Group + method channel.
///
/// WidgetKit widgets can't run Dart, so the widget extension can't call
/// back into this app's repository directly — instead we serialize just
/// enough data (the live match + each round's matches) into shared
/// storage every time it changes, and ask WidgetKit to redraw.
///
/// See ios/CopaBracketWidget/WIDGET_SETUP.md for the Xcode-side wiring
/// this pairs with (App Group entitlement + the widget extension target
/// itself, neither of which can be created from outside Xcode).
class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const _channel = MethodChannel('copa2026/widget_bridge');

  static Future<void> pushSnapshot(TournamentRepository repository) async {
    final snapshot = _buildSnapshot(repository);
    try {
      await _channel.invokeMethod<void>('updateSnapshot', jsonEncode(snapshot));
    } on MissingPluginException {
      // No native widget extension wired up yet — safe to ignore until
      // the Xcode-side target from WIDGET_SETUP.md exists.
    } on PlatformException catch (e) {
      // Native side reported a problem (e.g. the App Group entitlement
      // missing — see AppDelegate.swift). The widget staying stale must
      // never take the app itself down, so log-and-continue.
      debugPrint('HomeWidgetBridge: snapshot push failed: ${e.code} ${e.message}');
    }
  }

  static Map<String, dynamic> _matchJson(Match m) => {
        'id': m.id,
        'round': m.round.shortLabel,
        'flagA': m.flagA,
        'nameA': m.nameA,
        'flagB': m.flagB,
        'nameB': m.nameB,
        'scoreA': m.scoreA,
        'scoreB': m.scoreB,
        'status': m.status.name,
        'minute': m.liveMinute,
        'footer': m.footerLabel,
      };

  static Map<String, dynamic> _buildSnapshot(TournamentRepository repository) {
    const rounds = [Round.r16, Round.qf, Round.sf, Round.f];
    final live = repository.liveMatch;
    return {
      'updatedAt': DateTime.now().toIso8601String(),
      'live': live != null ? _matchJson(live) : null,
      'rounds': {
        for (final r in rounds) r.shortLabel: repository.matchesByRound(r).map(_matchJson).toList(),
      },
    };
  }
}
