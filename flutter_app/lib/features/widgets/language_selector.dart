import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/languages_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/language.dart';

/// Language selector widget.
/// 
/// Displays available languages fetched from the backend.
/// Automatically hides if there's only one or no languages available.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languagesState = ref.watch(languagesProvider);
    
    // Don't show selector if there's only one or no languages
    if (!languagesState.showSelector) {
      return const SizedBox.shrink();
    }
    
    final settings = ref.watch(settingsProvider);
    final languages = languagesState.languages;
    
    // Find current language
    final currentLang = languagesState.getLanguageForCode(settings.languageCode);

    return _LanguageSelectorButton(
      currentLanguage: currentLang,
      languages: languages,
      selectedCode: settings.languageCode,
      onLanguageSelected: (code) {
        ref.read(settingsProvider.notifier).setLanguage(code);
      },
    );
  }
}

/// Internal button widget for language selection.
class _LanguageSelectorButton extends StatelessWidget {
  final Language currentLanguage;
  final List<Language> languages;
  final String selectedCode;
  final ValueChanged<String> onLanguageSelected;

  const _LanguageSelectorButton({
    required this.currentLanguage,
    required this.languages,
    required this.selectedCode,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: selectedCode,
      onSelected: onLanguageSelected,
      itemBuilder: (context) => languages.map((lang) {
        final isSelected = lang.code == selectedCode;
        return PopupMenuItem<String>(
          value: lang.code,
          child: _LanguageMenuItem(
            language: lang,
            isSelected: isSelected,
          ),
        );
      }).toList(),
      child: _SelectorChip(language: currentLanguage),
    );
  }
}

/// Menu item for a single language option.
class _LanguageMenuItem extends StatelessWidget {
  final Language language;
  final bool isSelected;

  const _LanguageMenuItem({
    required this.language,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(language.icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: AppSpacing.sm),
        Text(
          language.nativeName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (isSelected) ...[
          const Spacer(),
          Icon(
            Icons.check_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ],
    );
  }
}

/// Chip displaying the currently selected language.
class _SelectorChip extends StatelessWidget {
  final Language language;

  const _SelectorChip({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(language.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
    );
  }
}
