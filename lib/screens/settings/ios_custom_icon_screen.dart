import 'package:flutter/foundation.dart';

import 'package:countdowns/models/app_icons.dart';
import 'package:countdowns/providers/local_settings_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IOSCustomIconScreen extends ConsumerWidget {
  const IOSCustomIconScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Icon')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 110,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 0.74,
        ),
        itemCount: appIcons.length,
        itemBuilder: (context, index) => IconGridTile(icon: appIcons[index]),
      ),
    );
  }
}

class IconGridTile extends ConsumerWidget {
  const IconGridTile({super.key, required this.icon});

  final AppIconOption icon;

  Future<void> _select(BuildContext context, WidgetRef ref) async {
    try {
      if (await FlutterDynamicIconPlus.supportsAlternateIcons) {
        await FlutterDynamicIconPlus.setAlternateIconName(
          iconName: icon.alternateIconName,
        );
        if (!context.mounted) return;
        ref.read(localSettingsProvider.notifier).setIconName(icon.slug);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected =
        appIconFor(ref.watch(localSettingsProvider).iconName).slug ==
            icon.slug &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS;
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '${icon.label} app icon',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _select(context, ref),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(0.2237 * 78),
                border: Border.all(
                  color: selected ? colorScheme.primary : Colors.transparent,
                  width: 3,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0.2237 * 66),
                child: Image.asset(icon.assetPath, width: 66, height: 66),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              icon.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
