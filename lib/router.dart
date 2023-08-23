import 'package:countdowns/screens/add_countdown_page.dart';
import 'package:countdowns/screens/countdown_page.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:countdowns/screens/settings_page.dart';
import 'package:flutter/material.dart';
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
        countdownEventKey: state.pathParameters['id'],
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) => const AddCountdownPage(),
    ),
  ],
  // errorBuilder: (context, state) => const PageNotFoundScreen(),
);
