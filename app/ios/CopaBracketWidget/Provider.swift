import WidgetKit

struct CopaWidgetEntry: TimelineEntry {
  let date: Date
  let snapshot: TournamentSnapshot
}

struct CopaWidgetProvider: TimelineProvider {
  // Must match kCopaWidgetAppGroupId in ios/Runner/AppDelegate.swift.
  static let appGroupId = "group.com.veogroup.worldcup2026"

  func placeholder(in context: Context) -> CopaWidgetEntry {
    CopaWidgetEntry(date: Date(), snapshot: .empty)
  }

  func getSnapshot(in context: Context, completion: @escaping (CopaWidgetEntry) -> Void) {
    completion(CopaWidgetEntry(date: Date(), snapshot: TournamentSnapshot.load(appGroupId: Self.appGroupId)))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CopaWidgetEntry>) -> Void) {
    let snapshot = TournamentSnapshot.load(appGroupId: Self.appGroupId)
    let entry = CopaWidgetEntry(date: Date(), snapshot: snapshot)
    // The bracket only changes a handful of times a day; a live match's
    // minute ticks in-app but WidgetKit refresh budgets are scarce, so
    // we ask for a modest 15-minute cadence rather than trying to track
    // it live from the widget itself.
    let nextRefresh = Date().addingTimeInterval(15 * 60)
    completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
  }
}
