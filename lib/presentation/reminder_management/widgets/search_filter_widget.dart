import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SearchFilterWidget extends StatefulWidget {
  final String searchQuery;
  final List<String> selectedCategories;
  final List<String> selectedStatuses;
  final List<String> selectedFrequencies;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<List<String>> onCategoriesChanged;
  final ValueChanged<List<String>> onStatusesChanged;
  final ValueChanged<List<String>> onFrequenciesChanged;
  final VoidCallback onClearAll;

  const SearchFilterWidget({
    super.key,
    required this.searchQuery,
    required this.selectedCategories,
    required this.selectedStatuses,
    required this.selectedFrequencies,
    required this.onSearchChanged,
    required this.onCategoriesChanged,
    required this.onStatusesChanged,
    required this.onFrequenciesChanged,
    required this.onClearAll,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  late TextEditingController _searchController;
  bool _isFilterExpanded = false;
  Timer? _debounceTimer;

  final List<String> _categories = [
    'spiritual',
    'family',
    'charity',
    'health',
    'work',
    'personal',
  ];

  final List<String> _statuses = [
    'active',
    'paused',
    'completed',
  ];

  final List<String> _frequencies = [
    'minutely',
    'hourly',
    'daily',
    'weekly',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      widget.onSearchChanged(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSearchBar(context),
          AnimatedContainer(
            duration: AppTheme.mediumAnimation,
            height: _isFilterExpanded ? null : 0,
            child: _isFilterExpanded ? _buildFilterOptions(context) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search reminders...',
                prefixIcon: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: CustomIconWidget(
                    iconName: 'search',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _debounceTimer?.cancel();
                          widget.onSearchChanged('');
                        },
                        icon: CustomIconWidget(
                          iconName: 'clear',
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          GestureDetector(
            onTap: () => _showFilterBottomSheet(context),
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CustomIconWidget(
                iconName: 'filter_list',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOptions(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          SizedBox(height: 2.h),
          _buildFilterSection(
            context,
            'Categories',
            _categories,
            widget.selectedCategories,
            widget.onCategoriesChanged,
          ),
          SizedBox(height: 2.h),
          _buildFilterSection(
            context,
            'Status',
            _statuses,
            widget.selectedStatuses,
            widget.onStatusesChanged,
          ),
          SizedBox(height: 2.h),
          _buildFilterSection(
            context,
            'Frequency',
            _frequencies,
            widget.selectedFrequencies,
            widget.onFrequenciesChanged,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClearAll,
                  child: Text('Clear All'),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() => _isFilterExpanded = false),
                  child: Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(
    BuildContext context,
    String title,
    List<String> options,
    List<String> selectedOptions,
    ValueChanged<List<String>> onChanged,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: options.map((option) {
            final isSelected = selectedOptions.contains(option);
            return FilterChip(
              label: Text(
                option.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                final newSelection = List<String>.from(selectedOptions);
                if (selected) {
                  newSelection.add(option);
                } else {
                  newSelection.remove(option);
                }
                onChanged(newSelection);
              },
              selectedColor: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainer,
              checkmarkColor: theme.colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 2.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Row(
                  children: [
                    Text(
                      'Filter Reminders',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Done'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Column(
                    children: [
                      _buildFilterSection(
                        context,
                        'Categories',
                        _categories,
                        widget.selectedCategories,
                        widget.onCategoriesChanged,
                      ),
                      SizedBox(height: 3.h),
                      _buildFilterSection(
                        context,
                        'Status',
                        _statuses,
                        widget.selectedStatuses,
                        widget.onStatusesChanged,
                      ),
                      SizedBox(height: 3.h),
                      _buildFilterSection(
                        context,
                        'Frequency',
                        _frequencies,
                        widget.selectedFrequencies,
                        widget.onFrequenciesChanged,
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.onClearAll();
                                Navigator.pop(context);
                              },
                              child: Text('Clear All'),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
