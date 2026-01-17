import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/enums.dart';
import '../../core/haptics/haptics_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/sound/sound_service.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/language_selector.dart';

/// Application settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Language section
          _buildSectionHeader(context, theme, context.tr('language'), Icons.language),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('appLanguage'),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const LanguageSelector(),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Game defaults section
          _buildSectionHeader(context, theme, context.tr('gameDefaults'), Icons.games),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Default timer
                  _buildTimerSetting(context, theme, ref, settings),
                  const Divider(height: AppSpacing.xl),

                  // Default age group
                  _buildAgeGroupSetting(context, theme, ref, settings),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Sound & Haptics section
          _buildSectionHeader(context, theme, context.tr('soundAndHaptics'), Icons.volume_up),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(context.tr('soundEffects')),
                  subtitle: Text(context.tr('playGameSounds')),
                  secondary: const Icon(Icons.music_note),
                  value: settings.soundEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleSound();
                    if (value) {
                      ref.read(soundServiceProvider).play(SoundEffect.buttonTap);
                    }
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: Text(context.tr('hapticFeedback')),
                  subtitle: Text(context.tr('vibrationOnActions')),
                  secondary: const Icon(Icons.vibration),
                  value: settings.hapticsEnabled,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleHaptics();
                    if (value) {
                      ref.read(hapticsServiceProvider).trigger(HapticType.light);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Theme section
          _buildSectionHeader(context, theme, context.tr('appearance'), Icons.palette),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text(context.tr('systemTheme')),
                  secondary: const Icon(Icons.settings_brightness),
                  value: ThemeMode.system,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text(context.tr('lightTheme')),
                  secondary: const Icon(Icons.light_mode),
                  value: ThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                    }
                  },
                ),
                const Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text(context.tr('darkTheme')),
                  secondary: const Icon(Icons.dark_mode),
                  value: ThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).setThemeMode(value);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Data section
          _buildSectionHeader(context, theme, context.tr('data'), Icons.storage),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_download),
                  title: Text(context.tr('syncData')),
                  subtitle: Text(context.tr('fetchLatestContent')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _syncData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
                  title: Text(
                    context.tr('clearLocalData'),
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: Text(context.tr('removeOfflineData')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _clearData(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // About section
          _buildSectionHeader(context, theme, context.tr('about'), Icons.info),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(context.tr('version')),
                  trailing: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(context.tr('privacyPolicy')),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Open privacy policy URL
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.article),
                  title: Text(context.tr('termsOfService')),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () {
                    // Open terms URL
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: Text(context.tr('licenses')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Truth or Dare',
                    applicationVersion: '1.0.0',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl * 2),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    ThemeData theme,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSetting(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    dynamic settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('defaultTimer'),
              style: theme.textTheme.titleMedium,
            ),
            Text(
              '${settings.defaultTimerSeconds}s',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Slider(
          value: settings.defaultTimerSeconds.toDouble(),
          min: 15,
          max: 120,
          divisions: 7,
          label: '${settings.defaultTimerSeconds}s',
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setDefaultTimer(value.toInt());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '15s',
              style: theme.textTheme.labelSmall,
            ),
            Text(
              '120s',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAgeGroupSetting(
    BuildContext context,
    ThemeData theme,
    WidgetRef ref,
    dynamic settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('defaultAgeGroup'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          children: AgeGroup.values.map((ageGroup) {
            final isSelected = settings.defaultAgeGroup == ageGroup.name;
            return ChoiceChip(
              label: Text(_getAgeGroupLabel(context, ageGroup)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  ref.read(settingsProvider.notifier).setDefaultAgeGroup(ageGroup);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getAgeGroupLabel(BuildContext context, AgeGroup ageGroup) {
    return switch (ageGroup) {
      AgeGroup.kids => context.tr('kids'),
      AgeGroup.teen => context.tr('teen'),
      AgeGroup.adults => context.tr('adults'),
    };
  }

  Future<void> _syncData(BuildContext context, WidgetRef ref) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.md),
                Text('Syncing data...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Simulate sync
    await Future.delayed(const Duration(seconds: 2));

    if (context.mounted) {
      Navigator.pop(context);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(context.tr('dataSynced')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('clearLocalData')),
        content: Text(context.tr('clearDataWarning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('clear')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('dataCleared')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
