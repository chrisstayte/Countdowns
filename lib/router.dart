import 'package:countdowns/screens/event_draft/event_draft_screen.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/settings/ios_custom_icon_screen.dart';
import 'package:countdowns/screens/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/event/:id',
      // builder: (context, state) => EventScreen(
      //   key: state.pageKey,
      //   eventKey: state.pathParameters['id']!,
      // ),
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        child: EventScreen(
          key: state.pageKey,
          eventKey: state.pathParameters['id']!,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: true,
          child: child,
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      // builder: (context, state) => const SettingsScreen(),
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            CupertinoFullscreenDialogTransition(
          primaryRouteAnimation: animation,
          secondaryRouteAnimation: secondaryAnimation,
          linearTransition: true,
          child: child,
        ),
      ),
      routes: [
        GoRoute(
          path: 'appIcon',
          builder: (context, state) => const IOSCustomIconScreen(),
        )
      ],
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
