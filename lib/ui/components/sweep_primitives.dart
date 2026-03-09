import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';

enum SweepSurfaceTone { standard, raised, muted, accent, danger }

enum SweepButtonVariant { primary, secondary, danger, ghost }

enum SweepButtonSize { compact, regular, hero }

class SweepChoice<T> {
  const SweepChoice({
    required this.value,
    required this.label,
    this.icon,
    this.detail,
  });

  final T value;
  final String label;
  final IconData? icon;
  final String? detail;
}

class SweepSurface extends StatelessWidget {
  const SweepSurface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.tone = SweepSurfaceTone.standard,
    this.borderRadius,
    this.gradient,
    this.blur = true,
    this.shadows = true,
    this.alignment,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final SweepSurfaceTone tone;
  final BorderRadiusGeometry? borderRadius;
  final Gradient? gradient;
  final bool blur;
  final bool shadows;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final BorderRadiusGeometry radius =
        borderRadius ?? BorderRadius.circular(theme.radii.md);
    final Color fill = switch (tone) {
      SweepSurfaceTone.standard => theme.colors.surface,
      SweepSurfaceTone.raised => theme.colors.surfaceRaised,
      SweepSurfaceTone.muted => theme.colors.surfaceMuted,
      SweepSurfaceTone.accent => theme.colors.primarySoft,
      SweepSurfaceTone.danger => theme.colors.danger.withValues(alpha: 0.16),
    };
    final Border border = Border.all(
      color: tone == SweepSurfaceTone.danger
          ? theme.colors.danger.withValues(alpha: 0.30)
          : theme.colors.border,
      width: 1,
    );

    Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? fill : null,
        gradient: gradient,
        borderRadius: radius,
        border: border,
        boxShadow: shadows ? theme.elevation.panel(0.85) : const <BoxShadow>[],
      ),
      child: Padding(
        padding: padding,
        child: alignment == null
            ? child
            : Align(alignment: alignment!, child: child),
      ),
    );

    if (blur) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: theme.blurSigma,
            sigmaY: theme.blurSigma,
          ),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

class SweepButton extends StatefulWidget {
  const SweepButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = SweepButtonVariant.primary,
    this.size = SweepButtonSize.regular,
    this.expand = false,
    this.textAlign = TextAlign.center,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final SweepButtonVariant variant;
  final SweepButtonSize size;
  final bool expand;
  final TextAlign textAlign;

  @override
  State<SweepButton> createState() => _SweepButtonState();
}

class _SweepButtonState extends State<SweepButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final bool enabled = widget.onPressed != null;
    final _SweepButtonStyle style = _styleFor(theme, widget.variant);
    final double minHeight = switch (widget.size) {
      SweepButtonSize.compact => 42,
      SweepButtonSize.regular => 50,
      SweepButtonSize.hero => 58,
    };
    final EdgeInsetsGeometry padding = switch (widget.size) {
      SweepButtonSize.compact =>
        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      SweepButtonSize.regular =>
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      SweepButtonSize.hero =>
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    };

    Widget content = AnimatedScale(
      scale: enabled && _pressed ? 0.98 : 1,
      duration: theme.motion.micro,
      curve: theme.motion.standard,
      child: AnimatedOpacity(
        duration: theme.motion.micro,
        opacity: enabled ? 1 : 0.42,
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          width: widget.expand ? double.infinity : null,
          padding: padding,
          decoration: BoxDecoration(
            color: style.gradient == null ? style.background : null,
            gradient: style.gradient,
            borderRadius: BorderRadius.circular(theme.radii.pill),
            border: Border.all(color: style.border),
            boxShadow: style.glowColor == null
                ? const <BoxShadow>[]
                : theme.elevation.glow(style.glowColor!, 0.6),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, size: 18, color: style.foreground),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: widget.textAlign,
                  style: theme.typography.button.copyWith(
                    color: style.foreground,
                    fontSize: widget.size == SweepButtonSize.hero ? 15 : 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    content = GestureDetector(
      onTap: widget.onPressed,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      child: content,
    );

    return Semantics(button: true, enabled: enabled, child: content);
  }

  _SweepButtonStyle _styleFor(
    SweepThemeData theme,
    SweepButtonVariant variant,
  ) {
    switch (variant) {
      case SweepButtonVariant.primary:
        return _SweepButtonStyle(
          background: theme.colors.primary,
          border: theme.colors.primary.withValues(alpha: 0.5),
          foreground: theme.colors.textOnAccent,
          gradient: LinearGradient(
            colors: <Color>[theme.colors.heroStart, theme.colors.heroEnd],
          ),
          glowColor: theme.colors.heroStart,
        );
      case SweepButtonVariant.secondary:
        return _SweepButtonStyle(
          background: theme.colors.surfaceRaised,
          border: theme.colors.borderStrong,
          foreground: theme.colors.textPrimary,
        );
      case SweepButtonVariant.danger:
        return _SweepButtonStyle(
          background: theme.colors.danger,
          border: theme.colors.danger.withValues(alpha: 0.7),
          foreground: theme.colors.textOnAccent,
          glowColor: theme.colors.danger,
        );
      case SweepButtonVariant.ghost:
        return _SweepButtonStyle(
          background: theme.colors.surface.withValues(alpha: 0.12),
          border: theme.colors.border,
          foreground: theme.colors.textPrimary,
        );
    }
  }
}

class _SweepButtonStyle {
  const _SweepButtonStyle({
    required this.background,
    required this.border,
    required this.foreground,
    this.gradient,
    this.glowColor,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final Gradient? gradient;
  final Color? glowColor;
}

class SweepPill extends StatelessWidget {
  const SweepPill({
    required this.text,
    this.icon,
    this.color,
    this.selected = false,
    this.filled = false,
    this.onTap,
    super.key,
  });

  final String text;
  final IconData? icon;
  final Color? color;
  final bool selected;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final Color tone = color ?? theme.colors.primary;
    final Color background = filled || selected
        ? tone.withValues(alpha: selected ? 0.18 : 0.14)
        : theme.colors.surfaceMuted;
    final Border border = Border.all(
      color: selected
          ? tone.withValues(alpha: 0.55)
          : theme.colors.border.withValues(alpha: 0.9),
    );

    Widget content = AnimatedContainer(
      duration: theme.motion.component,
      curve: theme.motion.standard,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      constraints: const BoxConstraints(maxWidth: 260),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(theme.radii.pill),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 15, color: tone),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: theme.typography.label.copyWith(
                color: selected ? tone : theme.colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      content = GestureDetector(onTap: onTap, child: content);
    }

    return content;
  }
}

class SweepSectionHeader extends StatelessWidget {
  const SweepSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.typography.title),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 6),
                Text(subtitle!, style: theme.typography.detail),
              ],
            ],
          ),
        ),
        ...(trailing == null ? const <Widget>[] : <Widget>[trailing!]),
      ],
    );
  }
}

class SweepPage extends StatelessWidget {
  const SweepPage({
    required this.title,
    required this.children,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.padding,
    this.controller,
    super.key,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return ListView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            theme.spacing.gutter,
            theme.spacing.lg,
            theme.spacing.gutter,
            176,
          ),
      children: <Widget>[
        if (eyebrow != null)
          Text(eyebrow!, style: theme.typography.caption),
        if (eyebrow != null) const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.typography.hero),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(subtitle!, style: theme.typography.detail),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 12),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class SweepSelector<T> extends StatelessWidget {
  const SweepSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    this.color,
    super.key,
  });

  final List<SweepChoice<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((SweepChoice<T> option) {
        final bool isSelected = option.value == selected;
        return GestureDetector(
          onTap: () => onSelected(option.value),
          child: AnimatedContainer(
            duration: theme.motion.component,
            curve: theme.motion.standard,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? (color ?? theme.colors.primary).withValues(alpha: 0.18)
                  : theme.colors.surfaceMuted,
              borderRadius: BorderRadius.circular(theme.radii.md),
              border: Border.all(
                color: isSelected
                    ? (color ?? theme.colors.primary).withValues(alpha: 0.55)
                    : theme.colors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (option.icon != null) ...<Widget>[
                  Icon(
                    option.icon,
                    size: 16,
                    color: isSelected
                        ? (color ?? theme.colors.primary)
                        : theme.colors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  option.label,
                  style: theme.typography.label.copyWith(
                    color: isSelected
                        ? (color ?? theme.colors.primary)
                        : theme.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class SweepTextField extends StatelessWidget {
  const SweepTextField({
    this.label,
    this.placeholder,
    this.controller,
    this.prefix,
    this.suffix,
    this.onSubmitted,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final Widget? prefix;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null) ...<Widget>[
          Text(label!, style: theme.typography.caption),
          const SizedBox(height: 8),
        ],
        SweepSurface(
          tone: SweepSurfaceTone.muted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          shadows: false,
          child: CupertinoTextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            placeholder: placeholder,
            onSubmitted: onSubmitted,
            style: theme.typography.body.copyWith(color: theme.colors.textPrimary),
            placeholderStyle: theme.typography.body.copyWith(
              color: theme.colors.textTertiary,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            prefix: prefix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: prefix,
                  ),
            suffix: suffix == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: suffix,
                  ),
            decoration: const BoxDecoration(),
            cursorColor: theme.colors.primary,
          ),
        ),
      ],
    );
  }
}

class SweepSelectField extends StatelessWidget {
  const SweepSelectField({
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.icon,
    super.key,
  });

  final String label;
  final String? value;
  final String? placeholder;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final String displayValue = value ?? placeholder ?? 'Choose';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.typography.caption),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: SweepSurface(
            tone: SweepSurfaceTone.muted,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            shadows: false,
            child: Row(
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, size: 18, color: theme.colors.textSecondary),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    displayValue,
                    style: theme.typography.body.copyWith(
                      color: value == null
                          ? theme.colors.textTertiary
                          : theme.colors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: theme.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SweepListRow extends StatelessWidget {
  const SweepListRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    Widget child = SweepSurface(
      tone: SweepSurfaceTone.standard,
      padding: padding,
      child: Row(
        children: <Widget>[
          if (leading != null) ...<Widget>[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.typography.bodyStrong),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(subtitle!, style: theme.typography.detail),
                ],
              ],
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      child = GestureDetector(onTap: onTap, child: child);
    }

    return child;
  }
}

class SweepProgressBar extends StatelessWidget {
  const SweepProgressBar({
    required this.value,
    this.color,
    this.height = 14,
    super.key,
  });

  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final Color tone = color ?? theme.colors.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radii.pill),
      child: Container(
        height: height,
        color: theme.colors.surfaceMuted,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
          duration: theme.motion.screen,
          curve: theme.motion.standard,
          builder: (BuildContext context, double animated, Widget? child) {
            return FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: animated,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      tone,
                      Color.lerp(tone, theme.colors.heroEnd, 0.35)!,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SweepAnimatedNumber extends StatelessWidget {
  const SweepAnimatedNumber({
    required this.value,
    required this.builder,
    super.key,
  });

  final num value;
  final String Function(num value) builder;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: theme.motion.screen,
      curve: theme.motion.standard,
      builder: (BuildContext context, double animated, Widget? child) {
        return Text(builder(animated));
      },
    );
  }
}

class SweepCheckIndicator extends StatelessWidget {
  const SweepCheckIndicator({
    required this.selected,
    this.color,
    super.key,
  });

  final bool selected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final Color tone = color ?? theme.colors.primary;

    return AnimatedContainer(
      duration: theme.motion.component,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? tone : theme.colors.surfaceRaised,
        border: Border.all(
          color: selected ? tone : theme.colors.borderStrong,
          width: 1.4,
        ),
      ),
      child: Icon(
        selected ? CupertinoIcons.check_mark : CupertinoIcons.circle,
        size: selected ? 13 : 10,
        color: selected ? theme.colors.textOnAccent : theme.colors.textTertiary,
      ),
    );
  }
}

class SweepEmptyState extends StatelessWidget {
  const SweepEmptyState({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return SweepSurface(
      tone: SweepSurfaceTone.raised,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colors.primarySoft,
            ),
            child: Icon(icon, size: 34, color: theme.colors.primary),
          ),
          const SizedBox(height: 14),
          Text(title, style: theme.typography.headline, textAlign: TextAlign.center),
          const SizedBox(height: 10),
          Text(
            body,
            style: theme.typography.detail,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...<Widget>[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

class SweepReveal extends StatefulWidget {
  const SweepReveal({
    required this.child,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final Duration delay;

  @override
  State<SweepReveal> createState() => _SweepRevealState();
}

class _SweepRevealState extends State<SweepReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: SweepThemeData.resolve(
        mode: SweepThemeMode.nocturne,
        reduceMotion: false,
      ).motion.screen,
    );
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SweepTheme.of(context).motion.reduceMotion) {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);
    final Animation<double> curved = CurvedAnimation(
      parent: _controller,
      curve: theme.motion.standard,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

Future<T?> showSweepDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final SweepThemeData theme = SweepTheme.of(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: theme.colors.scrim,
    transitionDuration: theme.motion.screen,
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return SweepThemeScope(
        theme: theme,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(builder: builder),
            ),
          ),
        ),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation curved = CurvedAnimation(
            parent: animation,
            curve: theme.motion.emphasized,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              child: child,
            ),
          );
        },
  );
}

Future<T?> showSweepSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final SweepThemeData theme = SweepTheme.of(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: theme.colors.scrim.withValues(alpha: 0.72),
    transitionDuration: theme.motion.screen,
    pageBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return SweepThemeScope(
        theme: theme,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 40, 14, 16),
              child: Builder(builder: builder),
            ),
          ),
        ),
      );
    },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation curved = CurvedAnimation(
            parent: animation,
            curve: theme.motion.emphasized,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.14),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
  );
}

class SweepDialogFrame extends StatelessWidget {
  const SweepDialogFrame({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: SweepSurface(
        tone: SweepSurfaceTone.raised,
        padding: const EdgeInsets.all(22),
        child: child,
      ),
    );
  }
}

class SweepSheetFrame extends StatelessWidget {
  const SweepSheetFrame({
    required this.child,
    this.maxWidth = 620,
    super.key,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final SweepThemeData theme = SweepTheme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SweepSurface(
        tone: SweepSurfaceTone.raised,
        borderRadius: BorderRadius.circular(theme.radii.lg),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 46,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colors.borderStrong,
                borderRadius: BorderRadius.circular(theme.radii.pill),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
