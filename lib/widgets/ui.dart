import 'package:countdowns/theme/app_theme.dart';
import 'package:countdowns/widgets/sliding_segmented.dart';
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

/// A row of options in a rounded track, one selected. A thin wrapper over
/// [SlidingSegmented] that keeps the original call sites' look.
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.height = 36,
    this.trackColor = AppColors.wash,
    this.selectedColor = AppColors.highlighter,
    this.selectedText = AppColors.ink,
    this.text = AppColors.ink,
    this.fontSize = 14,
    this.raised = false,
    this.scrollable = false,
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

  /// Label-sized options that scroll when they don't fit (see
  /// [SlidingSegmented.scrollable]).
  final bool scrollable;

  @override
  Widget build(BuildContext context) => SlidingSegmented<T>(
    values: values,
    selected: selected,
    label: label,
    onChanged: onChanged,
    height: height,
    fontSize: fontSize,
    trackColor: trackColor,
    pillColor: selectedColor,
    selectedText: selectedText,
    text: text,
    raised: raised,
    scrollable: scrollable,
  );
}

/// A chip-style single choice row (outlined options, ink pill), sliding
/// like the segmented control. Home filters, share Count in, Darken.
class ChipSegmented<T> extends StatelessWidget {
  const ChipSegmented({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.height = 38,
    this.fontSize = 14,
    this.spacing = 8,
    this.equalWidths = false,
    this.segmentPadding = 14,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final double height, fontSize, spacing, segmentPadding;
  final bool equalWidths;

  @override
  Widget build(BuildContext context) => SlidingSegmented<T>(
    values: values,
    selected: selected,
    label: label,
    onChanged: onChanged,
    height: height,
    fontSize: fontSize,
    fontWeight: FontWeight.w600,
    trackColor: null,
    spacing: spacing,
    outline: AppColors.border,
    equalWidths: equalWidths,
    segmentPadding: segmentPadding,
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
          color: selected ? AppColors.highlighter : background,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: selected ? AppColors.highlighter : AppColors.border,
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
                color: AppColors.ink,
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
    this.border,
  });

  final String label;
  final VoidCallback? onTap;
  final Color background, foreground;
  final double height;
  final IconData? icon;
  final bool shadow;
  final double fontSize;

  /// An outline (Save).
  final Color? border;

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
          border: border == null
              ? null
              : Border.all(color: border!, width: 1.5),
          boxShadow: shadow
              ? const [
                  BoxShadow(
                    color: Color(0x2E2E2A3A),
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
          color: value ? AppColors.ink : offTrack,
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

/// A screen title with a slightly tilted highlighter band behind its
/// lower half, like the app icon. For app screen titles only ("Countdowns",
/// "Settings"), never for countdown names.
class MarkedTitle extends StatelessWidget {
  const MarkedTitle(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final size =
        (style.fontSize ?? 34) * MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      header: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -size * 0.12,
            right: -size * 0.18,
            bottom: size * 0.06,
            height: size * 0.5,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: -0.025,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.highlighter,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(size * 0.08),
                      bottomLeft: Radius.circular(size * 0.2),
                      topRight: Radius.circular(size * 0.22),
                      bottomRight: Radius.circular(size * 0.1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Text(text, style: style),
        ],
      ),
    );
  }
}

/// The full-width secondary button under a section that opens its whole
/// catalogue: "All backgrounds", "All 68 icons", "All 11 fonts".
/// White with a Rule border, Ink label and a chevron; Wash while pressed.
class SeeAllButton extends StatefulWidget {
  const SeeAllButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<SeeAllButton> createState() => _SeeAllButtonState();
}

class _SeeAllButtonState extends State<SeeAllButton> {
  bool _pressed = false;

  void _press(bool down) {
    if (_pressed != down) setState(() => _pressed = down);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    excludeSemantics: true,
    onTap: widget.onTap,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press(true),
      onTapUp: (_) => _press(false),
      onTapCancel: () => _press(false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 44,
        padding: const EdgeInsets.only(left: 16, right: 10),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.wash : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.rule, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.ink,
            ),
          ],
        ),
      ),
    ),
  );
}
