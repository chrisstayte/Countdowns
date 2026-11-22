/// Links from the home and lock screen widgets into the app.
///
/// A widget opens `countdowns://event/<id>`. The app's own URL scheme is
/// registered on iOS (CFBundleURLTypes) and Android (an intent filter on
/// MainActivity), and Flutter hands the URL to GoRouter, whose top-level
/// redirect sends it through [widgetLinkRedirect]. That works the same on
/// a cold start (the first route) and in a running app (a pushed route).
library;

const widgetLinkScheme = 'countdowns';

/// The link a widget opens for one countdown. Written into the snapshot so
/// the native widgets never build links themselves.
Uri widgetLinkFor(int id) =>
    Uri(scheme: widgetLinkScheme, host: 'event', path: '/$id');

/// The countdown id in a widget link, or null if it is not one.
int? widgetLinkEventId(Uri uri) {
  if (uri.scheme != widgetLinkScheme || uri.host != 'event') return null;
  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  if (segments.length != 1) return null;
  return int.tryParse(segments.single);
}

/// Where a widget link lands: the countdown's detail screen (over Home, so
/// back returns there), or Home if the countdown is gone or the link is
/// malformed. Any other URL from outside the app (a scheme GoRouter can't
/// match, such as a launcher's own wrapper URI) also lands on Home rather
/// than an error page. Returns null for in-app paths, so ordinary
/// navigation is untouched.
Future<String?> widgetLinkRedirect(
  Uri uri,
  Future<bool> Function(int id) exists,
) async {
  if (!uri.hasScheme) return null;
  if (uri.scheme != widgetLinkScheme) return '/';
  final id = widgetLinkEventId(uri);
  if (id != null && await exists(id)) return '/event/$id';
  return '/';
}
