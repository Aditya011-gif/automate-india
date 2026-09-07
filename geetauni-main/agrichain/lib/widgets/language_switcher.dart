import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

/// Compact language switcher pill designed for AppBars.
class LanguageSwitcherPill extends StatelessWidget {
  final bool isDark;

  const LanguageSwitcherPill({super.key, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isHindi = appState.locale.languageCode == 'hi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          appState.toggleLanguage();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isHindi ? '🇮🇳 हिन्दी' : '🇬🇧 EN',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.swap_horiz,
                size: 14,
                color: isDark ? Colors.white70 : AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal bottom sheet to select language.
class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const LanguageSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final currentCode = appState.locale.languageCode;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentCode == 'hi' ? 'भाषा चुनें (Select Language)' : 'Select Language',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LanguageOption(
            title: 'English',
            subtitle: 'Default language',
            flag: '🇬🇧',
            isSelected: currentCode == 'en',
            onTap: () {
              appState.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _LanguageOption(
            title: 'हिन्दी (Hindi)',
            subtitle: 'भारतीय किसानों और व्यापारियों के लिए',
            flag: '🇮🇳',
            isSelected: currentCode == 'hi',
            onTap: () {
              appState.setLocale(const Locale('hi'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.08)
              : AppTheme.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
