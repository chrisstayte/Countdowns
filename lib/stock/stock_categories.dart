/// Stock photo categories. Our own list, independent of any photo source:
/// each maps to a search query, so any source (Pexels today, our own
/// catalogue later) can serve it.
class StockCategory {
  const StockCategory(
    this.id,
    this.label,
    this.query, {
    this.keywords = const [],
    this.window,
  });

  final String id;
  final String label;

  /// What a search-based source asks for.
  final String query;

  /// Lower-case words in a countdown's title that suggest this category.
  final List<String> keywords;

  /// When this category is in season, for ordering.
  final SeasonWindow? window;
}

/// A yearly window, inclusive, which may wrap the new year (Dec → Jan).
/// [peak] (month, day) orders categories that are in season together:
/// the soonest peak comes first.
class SeasonWindow {
  const SeasonWindow(this.start, this.end, this.peak);
  final (int, int) start, end, peak;

  static int _ord((int, int) md) => md.$1 * 100 + md.$2;

  bool contains(DateTime d) {
    final x = _ord((d.month, d.day));
    final s = _ord(start), e = _ord(end);
    return s <= e ? x >= s && x <= e : x >= s || x <= e;
  }

  /// Days from [now] to the next peak (0 on the day).
  int daysToPeak(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    var p = DateTime(now.year, peak.$1, peak.$2);
    if (p.isBefore(today)) p = DateTime(now.year + 1, peak.$1, peak.$2);
    return p.difference(today).inDays;
  }
}

const stockCategories = <StockCategory>[
  StockCategory(
    'thanksgiving',
    'Thanksgiving',
    'thanksgiving dinner autumn',
    keywords: ['thanksgiving', 'turkey', 'friendsgiving'],
    window: SeasonWindow((11, 1), (11, 28), (11, 26)),
  ),
  StockCategory(
    'christmas',
    'Christmas',
    'christmas',
    keywords: ['christmas', 'xmas', 'santa', 'holidays', 'advent'],
    window: SeasonWindow((11, 1), (12, 26), (12, 25)),
  ),
  StockCategory(
    'winter',
    'Winter',
    'winter snow',
    keywords: ['ski', 'snow', 'winter', 'skiing', 'snowboard'],
    window: SeasonWindow((11, 15), (2, 28), (12, 28)),
  ),
  StockCategory(
    'new-year',
    'New Year',
    'new year fireworks',
    keywords: ['new year', 'nye', 'countdown'],
    window: SeasonWindow((11, 20), (1, 7), (1, 1)),
  ),
  StockCategory(
    'valentines',
    'Valentine’s',
    'valentines day hearts',
    keywords: ['valentine', 'date night', 'love'],
    window: SeasonWindow((1, 20), (2, 14), (2, 14)),
  ),
  StockCategory(
    'easter',
    'Easter',
    'easter spring eggs',
    keywords: ['easter'],
    window: SeasonWindow((3, 1), (4, 25), (4, 5)),
  ),
  StockCategory(
    'halloween',
    'Halloween',
    'halloween pumpkin',
    keywords: ['halloween', 'spooky', 'costume', 'trick or treat'],
    window: SeasonWindow((10, 1), (10, 31), (10, 31)),
  ),
  StockCategory(
    'summer',
    'Summer',
    'summer sunshine',
    keywords: ['summer'],
    window: SeasonWindow((6, 1), (8, 31), (7, 15)),
  ),
  StockCategory(
    'birthday',
    'Birthday',
    'birthday party',
    keywords: ['birthday', 'bday', 'party', 'turns'],
  ),
  StockCategory(
    'wedding',
    'Wedding',
    'wedding',
    keywords: ['wedding', 'married', 'engagement', 'bride', 'honeymoon'],
  ),
  StockCategory(
    'anniversary',
    'Anniversary',
    'anniversary couple',
    keywords: ['anniversary'],
  ),
  StockCategory(
    'baby',
    'Baby',
    'baby',
    keywords: ['baby', 'due date', 'shower', 'born'],
  ),
  StockCategory(
    'graduation',
    'Graduation',
    'graduation',
    keywords: ['graduation', 'graduate', 'school', 'exam', 'semester'],
  ),
  StockCategory(
    'vacation',
    'Vacation',
    'travel vacation',
    keywords: [
      'trip',
      'vacation',
      'holiday',
      'travel',
      'flight',
      'getaway',
      'road trip',
      'cruise',
    ],
  ),
  StockCategory(
    'beach',
    'Beach',
    'beach',
    keywords: ['beach', 'island', 'hawaii', 'maldives', 'surf', 'coast'],
  ),
  StockCategory(
    'mountains',
    'Mountains',
    'mountains',
    keywords: ['mountain', 'hike', 'hiking', 'alps', 'trek'],
  ),
  StockCategory(
    'city',
    'City',
    'city skyline',
    keywords: [
      'city',
      'japan',
      'tokyo',
      'kyoto',
      'paris',
      'london',
      'new york',
      'nyc',
      'rome',
      'berlin',
      'seoul',
      'chicago',
    ],
  ),
  StockCategory(
    'camping',
    'Camping',
    'camping tent',
    keywords: ['camping', 'camp', 'tent', 'campfire'],
  ),
  StockCategory(
    'concert',
    'Concert',
    'concert stage',
    keywords: ['concert', 'gig', 'festival', 'tour', 'show'],
  ),
  StockCategory(
    'sports',
    'Sports',
    'sports',
    keywords: ['game', 'match', 'marathon', 'race', 'season', 'final'],
  ),
  StockCategory(
    'food',
    'Food',
    'food dinner',
    keywords: ['dinner', 'brunch', 'restaurant', 'bbq', 'feast'],
  ),
  StockCategory(
    'pets',
    'Pets',
    'cute pets',
    keywords: ['dog', 'puppy', 'cat', 'kitten', 'pet', 'gotcha day'],
  ),
  StockCategory('nature', 'Nature', 'nature landscape', keywords: ['nature']),
  StockCategory(
    'flowers',
    'Flowers',
    'flowers',
    keywords: ['flowers', 'garden', 'spring', 'bloom'],
  ),
  StockCategory(
    'space',
    'Space',
    'night sky stars',
    keywords: ['launch', 'eclipse', 'space', 'stars', 'meteor'],
  ),
  StockCategory('abstract', 'Abstract', 'abstract colorful background'),
];

/// Categories in the order the Photos tab shows them:
/// 1. ones whose keywords appear in [title] ("Japan trip" → Vacation, City),
/// 2. ones in season on [eventDate] (Dec 25 → Christmas),
/// 3. ones in season today, soonest peak first,
/// 4. everything else, in list order.
List<StockCategory> orderCategories(
  List<StockCategory> all,
  DateTime now, {
  DateTime? eventDate,
  String title = '',
}) {
  final t = ' ${title.toLowerCase()} ';
  bool mentions(StockCategory c) => c.keywords.any(
    (k) => RegExp('(^|[^a-z])${RegExp.escape(k)}([^a-z]|\$)').hasMatch(t),
  );
  final byTitle = all.where(mentions);
  final byEvent = eventDate == null
      ? const <StockCategory>[]
      : (all.where((c) => c.window?.contains(eventDate) ?? false).toList()
          ..sort(
            (a, b) => a.window!
                .daysToPeak(eventDate)
                .compareTo(b.window!.daysToPeak(eventDate)),
          ));
  final seasonal = all.where((c) => c.window?.contains(now) ?? false).toList()
    ..sort(
      (a, b) => a.window!.daysToPeak(now).compareTo(b.window!.daysToPeak(now)),
    );
  final seen = <String>{};
  return [
    for (final c in [...byTitle, ...byEvent, ...seasonal, ...all])
      if (seen.add(c.id)) c,
  ];
}
