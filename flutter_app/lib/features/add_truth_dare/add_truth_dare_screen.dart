import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/enums.dart';
import '../../core/haptics/haptics_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/categories_provider.dart';
import '../../core/sound/sound_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/models/task.dart';
import '../../data/models/category.dart';
import '../widgets/animated_button.dart';

/// Screen to add custom truths and dares.
class AddTruthDareScreen extends ConsumerStatefulWidget {
  const AddTruthDareScreen({super.key});

  @override
  ConsumerState<AddTruthDareScreen> createState() => _AddTruthDareScreenState();
}

class _AddTruthDareScreenState extends ConsumerState<AddTruthDareScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  
  TaskType _selectedType = TaskType.truth;
  AgeGroup _selectedAgeGroup = AgeGroup.adults;
  Category? _selectedCategory;
  String _selectedLanguage = 'en';

  final List<String> _supportedLanguages = ['en', 'es', 'fr', 'de', 'hi', 'gu'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('addTruthDare')),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.add),
              text: context.tr('addNew'),
            ),
            Tab(
              icon: const Icon(Icons.list),
              text: context.tr('myTasks'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddForm(context, theme, categoriesAsync),
          _buildMyTasks(context, theme),
        ],
      ),
    );
  }

  Widget _buildAddForm(
    BuildContext context,
    ThemeData theme,
    CategoriesState categoriesState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text(
              context.tr('taskType'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildTypeSelector(
                    context,
                    theme,
                    TaskType.truth,
                    '🎯',
                    context.tr('truth'),
                    AppColors.truthGradient,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildTypeSelector(
                    context,
                    theme,
                    TaskType.dare,
                    '🔥',
                    context.tr('dare'),
                    AppColors.dareGradient,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // Category selector
            Text(
              context.tr('category'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (categoriesState.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (categoriesState.error != null)
              Text(context.tr('errorLoadingCategories'))
            else
              DropdownButtonFormField<Category>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  hintText: context.tr('selectCategory'),
                ),
                items: categoriesState.categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Text(
                          category.icon,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(category.getName(_selectedLanguage)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return context.tr('pleaseSelectCategory');
                  }
                  return null;
                },
              ),

            const SizedBox(height: AppSpacing.xl),

            // Age group selector
            Text(
              context.tr('ageGroup'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: AgeGroup.values.map((ageGroup) {
                final isSelected = _selectedAgeGroup == ageGroup;
                return ChoiceChip(
                  label: Text(_getAgeGroupLabel(context, ageGroup)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedAgeGroup = ageGroup;
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Language selector
            Text(
              context.tr('language'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _supportedLanguages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return ChoiceChip(
                  label: Text(_getLanguageLabel(lang)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedLanguage = lang;
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Task text input
            Text(
              context.tr('taskText'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: _selectedType == TaskType.truth
                    ? context.tr('truthPlaceholder')
                    : context.tr('darePlaceholder'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.tr('pleaseEnterText');
                }
                if (value.trim().length < 10) {
                  return context.tr('textTooShort');
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Preview card
            if (_textController.text.isNotEmpty) ...[
              Text(
                context.tr('preview'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPreviewCard(context, theme),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              child: GameButton(
                text: context.tr('addTask'),
                icon: Icons.add,
                onPressed: _submitTask,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector(
    BuildContext context,
    ThemeData theme,
    TaskType type,
    String emoji,
    String label,
    List<Color> gradient,
  ) {
    final isSelected = _selectedType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(colors: gradient) : null,
          color: isSelected ? null : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: isSelected
              ? null
              : Border.all(color: theme.colorScheme.outline),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _selectedType == TaskType.truth
              ? AppColors.truthGradient
              : AppColors.dareGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  _selectedType == TaskType.truth
                      ? context.tr('truth')
                      : context.tr('dare'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (_selectedCategory != null)
                Text(
                  _selectedCategory!.icon,
                  style: const TextStyle(fontSize: 20),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _textController.text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyTasks(BuildContext context, ThemeData theme) {
    // This would load from local storage
    // For now, show placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_add_check,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr('noCustomTasks'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('addFirstTask'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  String _getAgeGroupLabel(BuildContext context, AgeGroup ageGroup) {
    return switch (ageGroup) {
      AgeGroup.kids => context.tr('kids'),
      AgeGroup.teen => context.tr('teen'),
      AgeGroup.adults => context.tr('adults'),
    };
  }

  String _getLanguageLabel(String code) {
    return switch (code) {
      'en' => 'English',
      'es' => 'Español',
      'fr' => 'Français',
      'de' => 'Deutsch',
      'hi' => 'हिन्दी',
      'gu' => 'ગુજરાતી',
      _ => code,
    };
  }

  void _submitTask() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ref.read(soundServiceProvider).play(SoundEffect.success);
    ref.read(hapticsServiceProvider).trigger(HapticType.success);

    // Create task
    // ignore: unused_local_variable
    final task = Task(
      id: const Uuid().v4(),
      categoryId: _selectedCategory!.id,
      type: _selectedType.name,
      ageGroup: _selectedAgeGroup.name,
      content: {_selectedLanguage: _textController.text.trim()},
    );

    // TODO: Save to local storage
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('taskAdded')),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: context.tr('addAnother'),
          onPressed: () {
            _textController.clear();
          },
        ),
      ),
    );

    // Clear form
    _textController.clear();
    setState(() {
      _selectedCategory = null;
    });
  }
}
