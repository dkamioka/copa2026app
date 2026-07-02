import SwiftUI
import WidgetKit

private let ink = Color(red: 0x16 / 255, green: 0x16 / 255, blue: 0x2E / 255)
private let accent = Color(red: 0xE1 / 255, green: 0x1D / 255, blue: 0x6B / 255)
private let bgTop = Color(red: 0xEE / 255, green: 0xF1 / 255, blue: 0xF7 / 255)
private let bgBottom = Color(red: 0xDC / 255, green: 0xE1 / 255, blue: 0xEE / 255)

private func background(_ content: some View) -> some View {
  content.containerBackground(for: .widget) {
    LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
  }
}

private struct Eyebrow: View {
  let text: String
  var body: some View {
    Text(text.uppercased())
      .font(.system(size: 10, weight: .bold))
      .tracking(1.1)
      .foregroundStyle(ink.opacity(0.45))
  }
}

private struct MatchRow: View {
  let match: WidgetMatch

  var body: some View {
    HStack(spacing: 7) {
      Text(match.flagA)
      Text(match.nameA)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(ink)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(match.scoreLine)
        .font(.system(size: 12, weight: .bold).monospacedDigit())
        .foregroundStyle(match.isLive ? accent : ink)
      Text(match.nameB)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(ink)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .trailing)
      Text(match.flagB)
    }
  }
}

struct CopaBracketWidgetSmallView: View {
  let entry: CopaWidgetEntry

  var body: some View {
    background(
      VStack(alignment: .leading, spacing: 8) {
        Eyebrow(text: "Mundial 2026")
        Spacer()
        if let live = entry.snapshot.live {
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
              Text("AO VIVO · \(live.minute ?? "")")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent)
            }
          }
          .frame(maxWidth: .infinity)
        } else if let next = entry.snapshot.featuredRoundMatches.first {
          VStack(spacing: 6) {
            HStack {
              Text(next.flagA).font(.system(size: 26))
              Spacer()
              Text(next.flagB).font(.system(size: 26))
            }
            Text(next.footer)
              .font(.system(size: 10.5, weight: .semibold))
              .foregroundStyle(ink.opacity(0.6))
          }
          .frame(maxWidth: .infinity)
        } else {
          Text("Sem jogos no momento")
            .font(.system(size: 11))
            .foregroundStyle(ink.opacity(0.5))
        }
        Spacer()
        Text(entry.snapshot.featuredRoundLabel)
          .font(.system(size: 9, weight: .bold))
          .foregroundStyle(ink.opacity(0.4))
      }
      .padding(14)
    )
    .widgetURL(URL(string: "copa2026://bracket"))
  }
}

struct CopaBracketWidgetMediumView: View {
  let entry: CopaWidgetEntry

  var body: some View {
    background(
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Eyebrow(text: "🏆 Mundial 2026")
          Spacer()
          Text(entry.snapshot.featuredRoundLabel)
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(ink.opacity(0.45))
        }
        VStack(spacing: 8) {
          ForEach(Array(entry.snapshot.featuredRoundMatches.prefix(2))) { match in
            MatchRow(match: match)
          }
        }
        Spacer(minLength: 0)
      }
      .padding(14)
    )
    .widgetURL(URL(string: "copa2026://bracket"))
  }
}

struct CopaBracketWidgetLargeView: View {
  let entry: CopaWidgetEntry

  var body: some View {
    background(
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Eyebrow(text: "🏆 Mundial 2026")
          Spacer()
          Text(entry.snapshot.featuredRoundLabel)
            .font(.system(size: 9.5, weight: .bold))
            .foregroundStyle(ink.opacity(0.45))
        }
        VStack(spacing: 10) {
          ForEach(Array(entry.snapshot.featuredRoundMatches.prefix(4))) { match in
            MatchRow(match: match)
            Divider().opacity(0.15)
          }
        }
        Spacer(minLength: 0)
        Text("Toque para abrir a chave completa")
          .font(.system(size: 9.5))
          .foregroundStyle(ink.opacity(0.4))
      }
      .padding(16)
    )
    .widgetURL(URL(string: "copa2026://bracket"))
  }
}

struct CopaBracketWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  let entry: CopaWidgetEntry

  var body: some View {
    // Keep in sync with .supportedFamilies below — .systemExtraLarge
    // isn't offered, so it isn't handled as a distinct case here.
    switch family {
    case .systemMedium:
      CopaBracketWidgetMediumView(entry: entry)
    case .systemLarge:
      CopaBracketWidgetLargeView(entry: entry)
    default:
      CopaBracketWidgetSmallView(entry: entry)
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
