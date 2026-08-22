import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool showElevation;
  final double? height;
  final VoidCallback? onBackPressed;

  const EnhancedAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.showElevation = true,
    this.height,
    this.onBackPressed,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(height ?? (subtitle != null ? 80.0 : 64.0));

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveBackgroundColor = backgroundColor ?? AppTheme.primaryGreen;

    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveBackgroundColor,
            effectiveBackgroundColor.withOpacity(0.9),
            AppTheme.lightGreen.withOpacity(0.8),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        boxShadow: showElevation
            ? [
                BoxShadow(
                  color: effectiveBackgroundColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading:
            leading ??
            (Navigator.canPop(context)
                ? IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: onBackPressed ?? () => Navigator.pop(context),
                    tooltip: 'Back',
                  )
                : null),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        centerTitle: centerTitle,
        actions: actions != null
            ? [
                ...actions!.map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: action,
                  ),
                ),
                const SizedBox(width: 8),
              ]
            : null,
        flexibleSpace: Container(
          decoration: const BoxDecoration(),
          child: ClipRect(
            child: Stack(
              children: [
                // Decorative background elements
                Positioned(
                  right: screenWidth * 0.15,
                  top: -10,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  right: screenWidth * 0.05,
                  bottom: -15,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                // Geometric accent lines
                Positioned(
                  right: 16,
                  top: 20,
                  child: Container(
                    width: 2,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Positioned(
                  right: 22,
                  top: 24,
                  child: Container(
                    width: 2,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
