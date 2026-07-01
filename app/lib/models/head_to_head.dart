class HeadToHead {
  final String fixture;
  final String competition;
  final String date;

  const HeadToHead({
    required this.fixture,
    required this.competition,
    required this.date,
  });
}

class TeamNewsItem {
  final String icon;
  final String text;

  const TeamNewsItem({required this.icon, required this.text});
}
