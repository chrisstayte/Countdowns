import 'package:countdowns/screens/add_countdown_page.dart';
import 'package:countdowns/screens/add_event/add_event_screen.dart';
import 'package:countdowns/screens/countdown_page.dart';
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
      builder: (context, state) => CountdownPage(
        key: state.pageKey,
        countdownEventKey: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddEventScreen(),
    ),
  ],
  // errorBuilder: (context, state) => const PageNotFoundScreen(),
);
