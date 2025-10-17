import '../models/reminder_template.dart';

/// Service for managing reminder templates and providing template-related functionality
class TemplateService {
  static const List<ReminderTemplate> _predefinedTemplates = [
    // Personal & Family (6 templates)
    ReminderTemplate(
      id: 'call_mom',
      title: 'Call mom',
      category: TemplateCategory.personal,
    ),
    ReminderTemplate(
      id: 'call_dad',
      title: 'Call dad',
      category: TemplateCategory.personal,
    ),
    ReminderTemplate(
      id: 'visit_family',
      title: 'Visit family',
      category: TemplateCategory.personal,
    ),
    ReminderTemplate(
      id: 'check_elderly_relatives',
      title: 'Check on elderly relatives',
      category: TemplateCategory.personal,
    ),
    ReminderTemplate(
      id: 'message_siblings',
      title: 'Send message to siblings',
      category: TemplateCategory.personal,
    ),
    ReminderTemplate(
      id: 'plan_family_gathering',
      title: 'Plan family gathering',
      category: TemplateCategory.personal,
    ),

    // Health & Wellness (5 templates)
    ReminderTemplate(
      id: 'take_medication',
      title: 'Take medication',
      category: TemplateCategory.health,
    ),
    ReminderTemplate(
      id: 'drink_water',
      title: 'Drink water',
      category: TemplateCategory.health,
    ),
    ReminderTemplate(
      id: 'exercise',
      title: 'Exercise',
      category: TemplateCategory.health,
    ),
    ReminderTemplate(
      id: 'go_for_walk',
      title: 'Go for a walk',
      category: TemplateCategory.health,
    ),
    ReminderTemplate(
      id: 'get_enough_sleep',
      title: 'Take a 20 minute nap',
      category: TemplateCategory.health,
    ),

    // Charity & Good Deeds (4 templates)
    ReminderTemplate(
      id: 'give_food_to_poor',
      title: 'Give food to poor',
      category: TemplateCategory.charity,
    ),
    ReminderTemplate(
      id: 'visit_sick',
      title: 'Visit the sick',
      category: TemplateCategory.charity,
    ),
    ReminderTemplate(
      id: 'help_neighbor',
      title: 'Help a neighbor',
      category: TemplateCategory.charity,
    ),
    ReminderTemplate(
      id: 'donate_to_charity',
      title: 'Donate to charity',
      category: TemplateCategory.charity,
    ),

    // Spiritual & Religious (3 templates)
    ReminderTemplate(
      id: 'read_quran',
      title: 'Read one page of Quran',
      category: TemplateCategory.spiritual,
    ),
    ReminderTemplate(
      id: 'make_dua',
      title: 'Ask Allah for fogivness',
      category: TemplateCategory.spiritual,
    ),
    ReminderTemplate(
      id: 'pray_on_time',
      title: 'Pray on time',
      category: TemplateCategory.spiritual,
    ),

    // Work & Productivity (2 templates)
    ReminderTemplate(
      id: 'pay_bills',
      title: 'Pay bills',
      category: TemplateCategory.work,
    ),
    ReminderTemplate(
      id: 'review_daily_goals',
      title: 'Review daily goals',
      category: TemplateCategory.work,
    ),
  ];

  /// Get all predefined templates with error handling
  static List<ReminderTemplate> getPredefinedTemplates() {
    try {
      if (_predefinedTemplates.isEmpty) {
        // Fallback: return minimal templates if main list is empty
        return List.unmodifiable(_getFallbackTemplates());
      }
      return List.unmodifiable(_predefinedTemplates);
    } catch (e) {
      // Graceful fallback: return minimal templates on any error
      return List.unmodifiable(_getFallbackTemplates());
    }
  }

  /// Fallback templates when main service fails
  static List<ReminderTemplate> _getFallbackTemplates() {
    return [
      const ReminderTemplate(
        id: 'call_mom_fallback',
        title: 'Call mom',
        category: TemplateCategory.personal,
      ),
      const ReminderTemplate(
        id: 'take_medication_fallback',
        title: 'Take medication',
        category: TemplateCategory.health,
      ),
      const ReminderTemplate(
        id: 'give_food_fallback',
        title: 'Give food to poor',
        category: TemplateCategory.charity,
      ),
    ];
  }

  /// Get templates filtered by category
  static List<ReminderTemplate> getTemplatesByCategory(String category) {
    if (!TemplateCategory.isValid(category)) {
      return [];
    }
    
    return _predefinedTemplates
        .where((template) => template.category == category)
        .toList();
  }

  /// Get the custom template option
  static ReminderTemplate getCustomTemplate() {
    return const ReminderTemplate(
      id: 'custom',
      title: 'Custom',
      category: TemplateCategory.custom,
      isCustom: true,
    );
  }

  /// Get the clear template option
  static ReminderTemplate getClearTemplate() {
    return const ReminderTemplate(
      id: 'clear',
      title: 'Clear',
      category: TemplateCategory.custom,
      isCustom: true,
    );
  }

  /// Get a random good deed template for prefilling
  static ReminderTemplate getRandomGoodDeed() {
    try {
      final templates = getPredefinedTemplates();
      if (templates.isEmpty) {
        return const ReminderTemplate(
          id: 'fallback_good_deed',
          title: 'Do a good deed',
          category: TemplateCategory.charity,
        );
      }
      
      // Use current time as seed for randomness
      final seed = DateTime.now().millisecondsSinceEpoch;
      final index = seed % templates.length;
      return templates[index];
    } catch (e) {
      // Fallback to a default good deed
      return const ReminderTemplate(
        id: 'fallback_good_deed',
        title: 'Do a good deed',
        category: TemplateCategory.charity,
      );
    }
  }

  /// Get all templates including custom option
  static List<ReminderTemplate> getAllTemplates() {
    final allTemplates = List<ReminderTemplate>.from(_predefinedTemplates);
    allTemplates.add(getCustomTemplate());
    return allTemplates;
  }

  /// Get template by ID
  static ReminderTemplate? getTemplateById(String id) {
    if (id == 'custom') {
      return getCustomTemplate();
    }
    
    if (id == 'clear') {
      return getClearTemplate();
    }
    
    try {
      return _predefinedTemplates.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get templates grouped by category
  static Map<String, List<ReminderTemplate>> getTemplatesGroupedByCategory() {
    final Map<String, List<ReminderTemplate>> grouped = {};
    
    for (final template in _predefinedTemplates) {
      if (!grouped.containsKey(template.category)) {
        grouped[template.category] = [];
      }
      grouped[template.category]!.add(template);
    }
    
    return grouped;
  }

  /// Get total count of predefined templates
  static int getTemplateCount() {
    return _predefinedTemplates.length;
  }

  /// Validate if template service has minimum required templates
  static bool hasMinimumTemplates() {
    return _predefinedTemplates.length >= 20;
  }
}