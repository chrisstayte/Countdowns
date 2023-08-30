import 'package:countdowns/screens/event_draft/event_draft_screen.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/settings_screen.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/event/:id',
      builder: (context, state) => EventScreen(
        key: state.pageKey,
        eventKey: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/eventDraft',
      builder: (context, state) => EventDraftScreen(
        key: state.pageKey,
      ),
    ),
    GoRoute(
      path: '/eventDraft/:id',
      builder: (context, state) => EventDraftScreen(
        key: state.pageKey,
        eventKey: state.pathParameters['id'],
      ),
    ),
  ],
  // errorBuilder: (context, state) => const PageNotFoundScreen(),
);
