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
  // Optional so snapshots written by older app builds still decode.
  let dateShort: String?
  let utc: String?
  let pens: String?
  let winner: String?

  var isLive: Bool { status == "live" }
  var isFinished: Bool { status == "finished" }
  var isUpcoming: Bool { !isLive && !isFinished }

  var scoreLine: String {
    guard let a = scoreA, let b = scoreB, status != "upcoming" else { return "vs" }
    return "\(a) – \(b)"
  }

  var kickoff: Date? {
    guard let utc else { return nil }
    // Dart's toIso8601String() carries fractional seconds.
    let withFraction = ISO8601DateFormatter()
    withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = withFraction.date(from: utc) { return d }
    return ISO8601DateFormatter().date(from: utc)
  }

  /// One-line context under the score: "AO VIVO · 63'", the kickoff
  /// date/time for upcoming games, or "Encerrado · 29/06 17:00" plus
  /// the shootout result when there was one.
  var caption: String {
    if isLive { return minute.map { "AO VIVO · \($0)" } ?? "AO VIVO" }
    let when = dateShort ?? footer
    if isFinished {
      var parts = ["Encerrado", when]
      if let pens { parts.append("Pên \(pens)") }
      return parts.joined(separator: " · ")
    }
    return when
  }
}

struct TournamentSnapshot: Codable {
  let updatedAt: String
  let live: WidgetMatch?
  let rounds: [String: [WidgetMatch]]

  static let empty = TournamentSnapshot(updatedAt: "", live: nil, rounds: [:])

  private static let roundOrder = ["16-avos", "Oitavas", "Quartas", "Semifinais", "Final"]

  /// The round to headline in the widget: the live match's round if
  /// there is one, otherwise the earliest round that still has
  /// matches left to play, falling back to the last round played.
  private var featuredRoundKey: String? {
    if let live, rounds[live.round] != nil { return live.round }
    for key in Self.roundOrder {
      if let matches = rounds[key], matches.contains(where: { !$0.isFinished }) {
        return key
      }
    }
    for key in Self.roundOrder.reversed() {
      if let matches = rounds[key], !matches.isEmpty { return key }
    }
    return nil
  }

  var featuredRoundLabel: String {
    featuredRoundKey ?? ""
  }

  /// The featured round's games in display order: the live one first,
  /// then upcoming games (soonest first), then finished games (most
  /// recent first).
  var featuredRoundMatches: [WidgetMatch] {
    guard let key = featuredRoundKey, let matches = rounds[key] else { return [] }
    let far = Date.distantFuture
    let live = matches.filter { $0.isLive }
    let upcoming = matches.filter { $0.isUpcoming }
      .sorted { ($0.kickoff ?? far) < ($1.kickoff ?? far) }
    let finished = matches.filter { $0.isFinished }
      .sorted { ($0.kickoff ?? .distantPast) > ($1.kickoff ?? .distantPast) }
    return live + upcoming + finished
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
