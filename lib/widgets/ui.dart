import 'package:countdowns/theme/app_theme.dart';
import 'package:material_ui/material_ui.dart';

/// Uppercase section heading.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Semantics(
          header: true,
          child: Text(text.toUpperCase(), style: AppText.eyebrow),
        ),
      ),
      ?trailing,
    ],
  );
}

/// A row of options in a rounded track, one selected.
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.height = 36,
    this.trackColor = AppColors.ground,
    this.selectedColor = AppColors.ink,
    this.selectedText = Colors.white,
    this.text = AppColors.ink,
    this.fontSize = 14,
    this.raised = false,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final double height;
  final Color trackColor, selectedColor, selectedText, text;
  final double fontSize;

  /// White selected pill with a shadow (editor tabs).
  final bool raised;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: trackColor,
      borderRadius: BorderRadius.circular(height / 2 + 4),
    ),
    child: Row(
      children: [
        for (final (i, v) in values.indexed) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              button: true,
              selected: v == selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: v == selected ? selectedColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(height / 2),
                    boxShadow: raised && v == selected
                        ? const [
                            BoxShadow(
                              color: Color(0x1F1C1633),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    label(v),
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: v == selected ? selectedText : text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// An outlined chip that fills ink when selected.
class ChoiceChipButton extends StatelessWidget {
  const ChoiceChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 38,
    this.trailing,
    this.background = Colors.transparent,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;
  final Widget? trailing;
  final Color background;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : background,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.ink,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    ),
  );
}

/// A 44pt round button.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.background = Colors.white,
    this.foreground = AppColors.ink,
    this.size = 44,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color background, foreground;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, size: 20, color: foreground),
        ),
      ),
    ),
  );
}

/// A pill-shaped text button: dark, green (save) or soft.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.background = AppColors.ink,
    this.foreground = Colors.white,
    this.height = 40,
    this.icon,
    this.shadow = false,
    this.fontSize = 15,
  });

  final String label;
  final VoidCallback? onTap;
  final Color background, foreground;
  final double height;
  final IconData? icon;
  final bool shadow;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: height >= 50 ? 22 : 18),
        decoration: BoxDecoration(
          color: onTap == null ? background.withValues(alpha: 0.5) : background,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x2E1C1633),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: foreground),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A text-only header action ("Cancel").
class TextAction extends StatelessWidget {
  const TextAction(this.label, {super.key, required this.onTap, this.color});
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color ?? AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The canvas's switch: green when on.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.offTrack = AppColors.border,
  });
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Color offTrack;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    label: label,
    child: GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 52,
        height: 32,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? AppColors.save : offTrack,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 3)],
          ),
        ),
      ),
    ),
  );
}

/// A white rounded group used in Settings and Search.
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.radius = 22});
  final List<Widget> children;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Column(children: children),
  );
}

/// The grab bar at the top of sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.only(top: 10, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}

/// A horizontal scroller that runs edge to edge past its parent's side
/// padding of [inset], with that inset moved inside the scroll content: at
/// rest the first item lines up with the page margin, and items scroll
/// under the screen edge instead of being cut off at the margin.
class BleedScroller extends StatelessWidget {
  const BleedScroller({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.inset = 20,
    this.spacing = 8,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double inset;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SizedBox(
      height: height,
      child: OverflowBox(
        minWidth: box.maxWidth + inset * 2,
        maxWidth: box.maxWidth + inset * 2,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: inset),
          clipBehavior: Clip.none,
          itemCount: itemCount,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: itemBuilder,
        ),
      ),
    ),
  );
}
