/// Data model for reminder templates used in quick template selection
class ReminderTemplate {
  final String id;
  final String title;
  final String category;
  final bool isCustom;

  const ReminderTemplate({
    required this.id,
    required this.title,
    required this.category,
    this.isCustom = false,
  });

  /// Validate template data integrity
  bool isValid() {
    return id.isNotEmpty &&
           title.isNotEmpty &&
           category.isNotEmpty;
  }

  @override
  String toString() {
    return 'ReminderTemplate(id: $id, title: $title, category: $category, isCustom: $isCustom)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderTemplate &&
           other.id == id &&
           other.title == title &&
           other.category == category &&
           other.isCustom == isCustom;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, category, isCustom);
  }
}

/// Template categories for organizing reminder templates
class TemplateCategory {
  static const String personal = 'personal';
  static const String health = 'health';
  static const String charity = 'charity';
  static const String spiritual = 'spiritual';
  static const String work = 'work';
  static const String custom = 'custom';

  static const List<String> _validCategories = [
    personal,
    health,
    charity,
    spiritual,
    work,
    custom,
  ];

  /// Check if category is valid
  static bool isValid(String category) {
    return _validCategories.contains(category);
  }

  /// Get all valid categories
  static List<String> get validCategories => List.unmodifiable(_validCategories);
}