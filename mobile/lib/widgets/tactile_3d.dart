import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Kartu 3D Bertekstur Mewah dengan Efek Bevel & Kedalaman Fisik (UI/UX Pro Max)
class Tactile3DCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isElevated;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  final Border? customBorder;

  const Tactile3DCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isElevated = false,
    this.backgroundColor,
    this.borderRadius,
    this.customBorder,
  });

  @override
  State<Tactile3DCard> createState() => _Tactile3DCardState();
}

class _Tactile3DCardState extends State<Tactile3DCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.borderRadius ?? BorderRadius.circular(18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      margin: widget.margin ?? EdgeInsets.zero,
      transform: Matrix4.translationValues(0, _isPressed ? 2.0 : 0.0, 0),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.cardWhite,
        gradient: widget.backgroundColor == null ? AppColors.cardGradient3D : null,
        borderRadius: r,
        border: widget.customBorder ??
            Border.all(
              color: AppColors.borderWarm,
              width: 1.2,
            ),
        boxShadow: _isPressed
            ? [
                BoxShadow(
                  color: const Color(0xFF261D17).withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : (widget.isElevated ? AppColors.shadow3DElevated : AppColors.shadow3D),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: widget.onTap,
          onHighlightChanged: (val) {
            if (widget.onTap != null) {
              setState(() => _isPressed = val);
            }
          },
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(16),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Tombol Fisik 3D dengan Efek Tekan Mekanikal (Tactile Push Response)
class Tactile3DButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final bool isLoading;
  final IconData? icon;

  const Tactile3DButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.textColor,
    this.height = 50,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<Tactile3DButton> createState() => _Tactile3DButtonState();
}

class _Tactile3DButtonState extends State<Tactile3DButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.backgroundColor ?? AppColors.brandEspresso;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
      onTapUp: isEnabled
          ? (_) {
              setState(() => _isPressed = false);
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: isEnabled ? () => setState(() => _isPressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutQuad,
        height: widget.height,
        transform: Matrix4.translationValues(0, _isPressed ? 3.0 : 0.0, 0),
        decoration: BoxDecoration(
          color: isEnabled ? bg : bg.withValues(alpha: 0.6),
          gradient: isEnabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg,
                    Color.alphaBlend(Colors.black.withValues(alpha: 0.18), bg),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
            right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.35), width: 2.0),
          ),
          boxShadow: _isPressed ? AppColors.buttonShadow3DPressed : AppColors.buttonShadow3D,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.textColor ?? Colors.white, size: 19),
                      const SizedBox(width: 8),
                    ],
                    DefaultTextStyle(
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: widget.textColor ?? Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                      child: widget.child,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
