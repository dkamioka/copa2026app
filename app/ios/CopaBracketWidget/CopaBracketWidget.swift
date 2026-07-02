import SwiftUI
import WidgetKit

private let ink = Color(red: 0x16 / 255, green: 0x16 / 255, blue: 0x2E / 255)
private let accent = Color(red: 0xE1 / 255, green: 0x1D / 255, blue: 0x6B / 255)
private let bgTop = Color(red: 0xEE / 255, green: 0xF1 / 255, blue: 0xF7 / 255)
private let bgBottom = Color(red: 0xDC / 255, green: 0xE1 / 255, blue: 0xEE / 255)

// The view tree here is deliberately flat — every block is its own
// small struct and the containerBackground/widgetURL modifiers are
// applied exactly once, at the entry view. A previous version composed
// one big generic body per family and crashed WidgetKit's archiver
// with a stack overflow (SIGSEGV at the stack guard) while
// instantiating the resulting type metadata, which renders as an
// all-black widget.

private struct Eyebrow: View {
  let text: String
  var body: some View {
    Text(text.uppercased())
      .font(.system(size: 10, weight: .bold))
      .tracking(1.1)
      .foregroundStyle(ink.opacity(0.45))
  }
}

private struct TeamName: View {
  let name: String
  let isWinner: Bool
  let dimmed: Bool
  let alignment: Alignment

  var body: some View {
    Text(name)
      .font(.system(size: 12, weight: isWinner ? .heavy : .semibold))
      .foregroundStyle(isWinner ? accent : ink.opacity(dimmed ? 0.55 : 1))
      .lineLimit(1)
      .frame(maxWidth: .infinity, alignment: alignment)
  }
}

/// Two-line row: teams + score, then a caption with the game's state
/// and date/time. Finished games are dimmed with the advancing team
/// highlighted; upcoming games stay at full strength.
private struct MatchRow: View {
  let match: WidgetMatch

  var body: some View {
    VStack(spacing: 2) {
      HStack(spacing: 7) {
        Text(match.flagA).opacity(match.isFinished ? 0.75 : 1)
        TeamName(
          name: match.nameA,
          isWinner: match.winner == "a",
          dimmed: match.isFinished,
          alignment: .leading
        )
        Text(match.scoreLine)
          .font(.system(size: 12, weight: .bold).monospacedDigit())
          .foregroundStyle(match.isLive ? accent : ink.opacity(match.isFinished ? 0.7 : 1))
        TeamName(
          name: match.nameB,
          isWinner: match.winner == "b",
          dimmed: match.isFinished,
          alignment: .trailing
        )
        Text(match.flagB).opacity(match.isFinished ? 0.75 : 1)
      }
      Text(match.caption)
        .font(.system(size: 8.5, weight: match.isUpcoming ? .bold : .medium))
        .foregroundStyle(
          match.isLive ? accent : ink.opacity(match.isUpcoming ? 0.65 : 0.4)
        )
        .lineLimit(1)
    }
  }
}

private struct LiveBlock: View {
  let live: WidgetMatch

  var body: some View {
    VStack(spacing: 6) {
      HStack {
        Text(live.flagA).font(.system(size: 30))
        Spacer()
        Text(live.flagB).font(.system(size: 30))
      }
      Text(live.scoreLine)
        .font(.system(size: 22, weight: .heavy).monospacedDigit())
        .foregroundStyle(ink)
      HStack(spacing: 5) {
        Circle().fill(accent).frame(width: 6, height: 6)
        Text(live.minute.map { "AO VIVO · \($0)" } ?? "AO VIVO")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(accent)
      }
    }
    .frame(maxWidth: .infinity)
  }
}

private struct NextBlock: View {
  let next: WidgetMatch

  var body: some View {
    VStack(spacing: 6) {
      HStack {
        Text(next.flagA).font(.system(size: 26))
        Spacer()
        Text(next.flagB).font(.system(size: 26))
      }
      Text(next.caption)
        .font(.system(size: 10.5, weight: .semibold))
        .foregroundStyle(ink.opacity(0.6))
    }
    .frame(maxWidth: .infinity)
  }
}

private struct SmallContent: View {
  let snapshot: TournamentSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Eyebrow(text: "Mundial 2026")
      Spacer()
      centerBlock
      Spacer()
      Text(snapshot.featuredRoundLabel)
        .font(.system(size: 9, weight: .bold))
        .foregroundStyle(ink.opacity(0.4))
    }
  }

  @ViewBuilder private var centerBlock: some View {
    if let live = snapshot.live {
      LiveBlock(live: live)
    } else if let next = snapshot.featuredRoundMatches.first {
      NextBlock(next: next)
    } else {
      Text("Sem jogos no momento")
        .font(.system(size: 11))
        .foregroundStyle(ink.opacity(0.5))
    }
  }
}

private struct HeaderRow: View {
  let roundLabel: String

  var body: some View {
    HStack {
      Eyebrow(text: "🏆 Mundial 2026")
      Spacer()
      Text(roundLabel)
        .font(.system(size: 9.5, weight: .bold))
        .foregroundStyle(ink.opacity(0.45))
    }
  }
}

private struct MediumContent: View {
  let snapshot: TournamentSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HeaderRow(roundLabel: snapshot.featuredRoundLabel)
      VStack(spacing: 8) {
        ForEach(Array(snapshot.featuredRoundMatches.prefix(2))) { match in
          MatchRow(match: match)
        }
      }
      Spacer(minLength: 0)
    }
  }
}

private struct LargeContent: View {
  let snapshot: TournamentSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 9) {
      HeaderRow(roundLabel: snapshot.featuredRoundLabel)
      VStack(spacing: 7) {
        ForEach(Array(snapshot.featuredRoundMatches.prefix(4))) { match in
          VStack(spacing: 7) {
            MatchRow(match: match)
            Divider().opacity(0.15)
          }
        }
      }
      Spacer(minLength: 0)
      Text("Toque para abrir a chave completa")
        .font(.system(size: 9.5))
        .foregroundStyle(ink.opacity(0.4))
    }
  }
}

struct CopaBracketWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  let entry: CopaWidgetEntry

  var body: some View {
    content
      .padding(family == .systemLarge ? 16 : 14)
      .widgetURL(URL(string: "copa2026://bracket"))
      .containerBackground(for: .widget) {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
      }
  }

  @ViewBuilder private var content: some View {
    switch family {
    case .systemMedium:
      MediumContent(snapshot: entry.snapshot)
    case .systemLarge:
      LargeContent(snapshot: entry.snapshot)
    default:
      SmallContent(snapshot: entry.snapshot)
    }
  }
}

struct CopaBracketWidget: Widget {
  let kind: String = "CopaBracketWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: CopaWidgetProvider()) { entry in
      CopaBracketWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Mundial 2026")
    .description("Acompanhe o jogo ao vivo e a rodada atual das eliminatórias.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}
