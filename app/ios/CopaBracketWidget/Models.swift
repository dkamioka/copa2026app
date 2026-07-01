import Foundation

/// Mirrors the JSON shape written by `HomeWidgetBridge` in the Flutter
/// app (lib/widget_bridge/home_widget_bridge.dart). Keep the two in
/// sync if either side changes field names.
struct WidgetMatch: Codable, Identifiable {
  let id: String
  let round: String
  let flagA: String
  let nameA: String
  let flagB: String
  let nameB: String
  let scoreA: Int?
  let scoreB: Int?
  let status: String
  let minute: String?
  let footer: String

  var isLive: Bool { status == "live" }
  var isFinished: Bool { status == "finished" }

  var scoreLine: String {
    guard let a = scoreA, let b = scoreB, status != "upcoming" else { return "vs" }
    return "\(a) – \(b)"
  }
}

struct TournamentSnapshot: Codable {
  let updatedAt: String
  let live: WidgetMatch?
  let rounds: [String: [WidgetMatch]]

  static let empty = TournamentSnapshot(updatedAt: "", live: nil, rounds: [:])

  /// The round to headline in the widget: the live match's round if
  /// there is one, otherwise the earliest round that still has
  /// matches left to play, falling back to the last round played.
  var featuredRoundMatches: [WidgetMatch] {
    let order = ["Oitavas", "Quartas", "Semifinais", "Final"]
    if let live, let liveRound = rounds[live.round] { return liveRound }
    for key in order {
      if let matches = rounds[key], matches.contains(where: { !$0.isFinished }) {
        return matches
      }
    }
    for key in order.reversed() {
      if let matches = rounds[key], !matches.isEmpty { return matches }
    }
    return []
  }

  var featuredRoundLabel: String {
    let order = ["Oitavas", "Quartas", "Semifinais", "Final"]
    if let live { return live.round }
    for key in order {
      if let matches = rounds[key], matches.contains(where: { !$0.isFinished }) { return key }
    }
    return order.last ?? ""
  }

  static func load(appGroupId: String) -> TournamentSnapshot {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let json = defaults.string(forKey: "bracket_snapshot"),
      let data = json.data(using: .utf8),
      let snapshot = try? JSONDecoder().decode(TournamentSnapshot.self, from: data)
    else {
      return .empty
    }
    return snapshot
  }
}
