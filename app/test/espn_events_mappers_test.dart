import 'package:flutter_test/flutter_test.dart';
import 'package:worldcup2026/data/espn/espn_events_mappers.dart';
import 'package:worldcup2026/models/match_event.dart';

// Real shapes from the live ESPN 2026 World Cup feed (Brazil x Japan,
// 2026-06-29), reduced to the fields the mappers read.
Map<String, dynamic> _scoreboard() => {
      'events': [
        {
          'id': '760489',
          'competitions': [
            {
              'competitors': [
                {'homeAway': 'home', 'team': {'displayName': 'Germany'}},
                {'homeAway': 'away', 'team': {'displayName': 'Paraguay'}},
              ],
            },
          ],
        },
        {
          'id': '760487',
          'competitions': [
            {
              'competitors': [
                {'homeAway': 'home', 'team': {'displayName': 'Brazil'}},
                {'homeAway': 'away', 'team': {'displayName': 'Japan'}},
              ],
            },
          ],
        },
      ],
    };

Map<String, dynamic> _summary() => {
      'header': {
        'competitions': [
          {
            'competitors': [
              {'homeAway': 'home', 'team': {'displayName': 'Brazil'}},
              {'homeAway': 'away', 'team': {'displayName': 'Japan'}},
            ],
          },
        ],
      },
      'keyEvents': [
        {
          'type': {'text': 'Kickoff'},
          'clock': {'displayValue': ''},
          'shootout': false,
        },
        {
          'type': {'text': 'Yellow Card'},
          'clock': {'displayValue': "14'"},
          'team': {'displayName': 'Brazil'},
          'participants': [
            {'athlete': {'displayName': 'Casemiro'}},
          ],
          'shootout': false,
        },
        {
          'type': {'text': 'Goal'},
          'scoringPlay': true,
          'clock': {'displayValue': "29'"},
          'team': {'displayName': 'Japan'},
          'participants': [
            {'athlete': {'displayName': 'Kaishu Sano'}},
          ],
          'shootout': false,
        },
        {
          'type': {'text': 'Penalty - Scored'},
          'scoringPlay': true,
          'clock': {'displayValue': "45'+4'"},
          'team': {'displayName': 'Brazil'},
          'participants': [
            {'athlete': {'displayName': 'Vinícius Júnior'}},
          ],
          'shootout': false,
        },
        {
          // Shootout kicks must not appear in the match timeline.
          'type': {'text': 'Penalty - Scored'},
          'scoringPlay': true,
          'clock': {'displayValue': ''},
          'team': {'displayName': 'Japan'},
          'participants': [
            {'athlete': {'displayName': 'Someone'}},
          ],
          'shootout': true,
        },
        {
          'type': {'text': 'Substitution'},
          'clock': {'displayValue': "45'"},
          'team': {'displayName': 'Brazil'},
          'shootout': false,
        },
      ],
    };

void main() {
  test('findEventId matches fixtures by resolved team names', () {
    expect(
      EspnEventsMappers.findEventId(_scoreboard(), home: 'Brazil', away: 'Japan'),
      '760487',
    );
    expect(
      EspnEventsMappers.findEventId(_scoreboard(), home: 'France', away: 'Sweden'),
      isNull,
    );
  });

  test('eventsFromSummary keeps goals and cards, drops the rest', () {
    final events = EspnEventsMappers.eventsFromSummary(_summary());
    expect(events, hasLength(3));

    expect(events[0].type, MatchEventType.yellowCard);
    expect(events[0].player, 'Casemiro');
    expect(events[0].side, MatchSide.a);
    expect(events[0].minute, 14);

    expect(events[1].type, MatchEventType.goal);
    expect(events[1].player, 'Kaishu Sano');
    expect(events[1].side, MatchSide.b);
    expect(events[1].minute, 29);

    // Stoppage-time penalty: base minute, penaltyGoal type.
    expect(events[2].type, MatchEventType.penaltyGoal);
    expect(events[2].minute, 45);
    expect(events[2].side, MatchSide.a);
  });
}
