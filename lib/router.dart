import 'package:countdowns/constants.dart';
import 'package:countdowns/screens/event_form/event_form_screen.dart';
import 'package:countdowns/screens/event_form/options/name_and_date/date_picker_screen.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/search/search_screen.dart';
import 'package:countdowns/screens/settings/ios_custom_icon_screen.dart';
import 'package:countdowns/screens/settings/settings_screen.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
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
                    EventFormScreen(eventKey: state.pathParameters['id']),
                routes: [_dateRoute(AppRoutes.editDate)],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.eventNew,
            name: AppRoutes.eventNew,
            builder: (_, _) => const EventFormScreen(),
            routes: [_dateRoute(AppRoutes.newDate)],
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

GoRoute _dateRoute(String name) => GoRoute(
  path: 'date',
  name: name,
  builder: (_, state) => DatePickerScreen(
    eventDateTime: DateTime.tryParse(state.uri.queryParameters['date'] ?? ''),
    allDay: state.uri.queryParameters['allDay'] != 'false',
  ),
);
