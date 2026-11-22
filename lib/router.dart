import 'package:countdowns/constants.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/screens/editor/editor_screen.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/search/search_screen.dart';
import 'package:countdowns/screens/tablet/wall_screen.dart';
import 'package:countdowns/screens/settings/ios_custom_icon_screen.dart';
import 'package:countdowns/screens/settings/settings_screen.dart';
import 'package:countdowns/widgets_bridge/widget_links.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    // Widget taps arrive as countdowns://event/<id>. Ask the database
    // itself, not the events stream: on a cold start nothing listens to the
    // stream yet, so it would never deliver. A deleted countdown falls back
    // to Home instead of an empty detail.
    redirect: (_, state) => widgetLinkRedirect(
      state.uri,
      (id) async => (await ref.read(databaseProvider).allCountdowns()).any(
        (e) => e.id == id,
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.home,
        builder: (_, _) => const HomeScreen(),
        routes: [
          GoRoute(
            path: AppRoutes.event,
            name: AppRoutes.event,
            pageBuilder: (_, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: EventScreen(eventKey: state.pathParameters['id']!),
              transitionsBuilder: (_, animation, secondary, child) =>
                  CupertinoFullscreenDialogTransition(
                    primaryRouteAnimation: animation,
                    secondaryRouteAnimation: secondary,
                    linearTransition: true,
                    child: child,
                  ),
            ),
            routes: [
              GoRoute(
                path: AppRoutes.eventEdit,
                name: AppRoutes.eventEdit,
                builder: (_, state) =>
                    EditorScreen(eventKey: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.eventNew,
            name: AppRoutes.eventNew,
            builder: (_, state) => EditorScreen(
              title: state.uri.queryParameters['title'],
              date: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
            ),
          ),
          GoRoute(
            path: AppRoutes.search,
            name: AppRoutes.search,
            pageBuilder: (_, state) => CustomTransitionPage<void>(
              key: state.pageKey,
              child: const SearchScreen(),
              transitionsBuilder: (_, animation, _, child) =>
                  FadeTransition(opacity: animation, child: child),
            ),
          ),
          GoRoute(
            path: AppRoutes.wall,
            name: AppRoutes.wall,
            builder: (_, _) => const WallScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.appIcon,
                name: AppRoutes.appIcon,
                builder: (_, _) => const IOSCustomIconScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) =>
        const Scaffold(body: Center(child: Text('Page No Found'))),
  );
  ref.onDispose(router.dispose);
  return router;
});
