import 'package:countdowns/constants.dart';
import 'package:countdowns/screens/home/home_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// iPad Home. Filled in by the split view step.
class TabletHome extends ConsumerWidget {
  const TabletHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: HomeList(
      columns: 4,
      onOpen: (e) =>
          context.pushNamed(AppRoutes.event, pathParameters: {'id': '${e.id}'}),
    ),
  );
}
