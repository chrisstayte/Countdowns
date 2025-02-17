import 'package:countdowns/constants.dart';
import 'package:countdowns/global/global.dart';
import 'package:countdowns/providers/countdowns_provider.dart';
import 'package:countdowns/providers/event_provider.dart';
import 'package:countdowns/providers/timer_provider.dart';
import 'package:countdowns/screens/event_form/event_form_screen.dart';
import 'package:countdowns/screens/event_screen/event_screen.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/settings/ios_custom_icon_screen.dart';
import 'package:countdowns/screens/settings/settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _mainNavigatorKey = GlobalKey<NavigatorState>();

Page getPage({required Widget child, required GoRouterState state}) {
  return MaterialPage(key: state.pageKey, child: child);
}

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    redirect: (context, state) {
      debugPrint('Redirecting to ${state.uri}');
      return null;
    },
    routes: [
      ShellRoute(
        parentNavigatorKey: _rootNavigatorKey,
        navigatorKey: _mainNavigatorKey,
        pageBuilder:
            (context, state, child) => getPage(
              child: MultiProvider(
                providers: [
                  ChangeNotifierProvider<EventProvider>(
                    create: (_) => EventProvider(),
                    lazy: false,
                  ),
                  ChangeNotifierProvider<TimerProvider>(
                    create: (_) => TimerProvider(),
                  ),
                ],
                child: child,
              ),
              state: state,
            ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: AppRoutes.event,
                name: AppRoutes.event,
                pageBuilder: (context, state) {
                  return CustomTransitionPage<void>(
                    child: EventScreen(
                      key: state.pageKey,
                      eventKey: state.pathParameters['id']!,
                    ),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) =>
                            CupertinoFullscreenDialogTransition(
                              primaryRouteAnimation: animation,
                              secondaryRouteAnimation: secondaryAnimation,
                              linearTransition: true,
                              child: child,
                            ),
                  );
                },
                routes: [
                  GoRoute(
                    name: AppRoutes.eventEdit,
                    path: AppRoutes.eventEdit,
                    builder:
                        (context, state) => EventFormScreen(
                          key: state.pageKey,
                          eventKey: state.pathParameters['id'],
                        ),
                  ),
                ],
              ),
              GoRoute(
                path: AppRoutes.eventNew,
                name: AppRoutes.eventNew,
                builder:
                    (context, state) => EventFormScreen(key: state.pageKey),
              ),

              GoRoute(
                path: AppRoutes.settings,
                name: AppRoutes.settings,

                builder: (context, state) => const SettingsScreen(),
                // pageBuilder:
                //     (context, state) => CustomTransitionPage<void>(
                //       opaque: false,
                //       barrierColor: Colors.black.withAlpha(150),
                //       child: const SettingsScreen(),
                //       transitionsBuilder:
                //           (context, animation, secondaryAnimation, child) =>
                //               CupertinoSheetTransition(
                //                 primaryRouteAnimation: animation,
                //                 secondaryRouteAnimation: secondaryAnimation,
                //                 linearTransition: false,
                //                 child: child,
                //               ),
                //     ),
                routes: [
                  GoRoute(
                    name: AppRoutes.appIcon,
                    path: AppRoutes.appIcon,
                    builder: (context, state) => const IOSCustomIconScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          body: const Placeholder(child: Center(child: Text('Page No Found'))),
        ),
  );
}
