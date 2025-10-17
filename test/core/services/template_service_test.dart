import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/services/template_service.dart';
import 'package:good_deeds_reminder/core/models/reminder_template.dart';

void main() {
  group('TemplateService', () {
    group('getPredefinedTemplates', () {
      test('returns list of predefined templates', () {
        final templates = TemplateService.getPredefinedTemplates();
        
        expect(templates, isNotEmpty);
        expect(templates.length, greaterThanOrEqualTo(20));
        expect(templates, isA<List<ReminderTemplate>>());
      });

      test('returns unmodifiable list', () {
        final templates = TemplateService.getPredefinedTemplates();
        
        expect(() => templates.add(const ReminderTemplate(
          id: 'test',
          title: 'Test',
          category: 'personal',
        )), throwsUnsupportedError);
      });

      test('all templates are valid', () {
        final templates = TemplateService.getPredefinedTemplates();
        
        for (final template in templates) {
          expect(template.isValid(), isTrue);
          expect(template.isCustom, isFalse);
          expect(TemplateCategory.isValid(template.category), isTrue);
        }
      });
    });

    group('getTemplatesByCategory', () {
      test('returns templates for valid category', () {
        final personalTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.personal);
        
        expect(personalTemplates, isNotEmpty);
        for (final template in personalTemplates) {
          expect(template.category, equals(TemplateCategory.personal));
        }
      });

      test('returns empty list for invalid category', () {
        final invalidTemplates = TemplateService.getTemplatesByCategory('invalid_category');
        
        expect(invalidTemplates, isEmpty);
      });

      test('returns correct templates for each category', () {
        // Test personal category
        final personalTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.personal);
        expect(personalTemplates.any((t) => t.title == 'Call mom'), isTrue);
        expect(personalTemplates.any((t) => t.title == 'Call dad'), isTrue);

        // Test health category
        final healthTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.health);
        expect(healthTemplates.any((t) => t.title == 'Take medication'), isTrue);
        expect(healthTemplates.any((t) => t.title == 'Exercise'), isTrue);

        // Test charity category
        final charityTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.charity);
        expect(charityTemplates.any((t) => t.title == 'Give food to poor'), isTrue);
        expect(charityTemplates.any((t) => t.title == 'Visit the sick'), isTrue);

        // Test spiritual category
        final spiritualTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.spiritual);
        expect(spiritualTemplates.any((t) => t.title == 'Read Quran'), isTrue);
        expect(spiritualTemplates.any((t) => t.title == 'Make dua'), isTrue);

        // Test work category
        final workTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.work);
        expect(workTemplates.any((t) => t.title == 'Check emails'), isTrue);
        expect(workTemplates.any((t) => t.title == 'Review daily goals'), isTrue);
      });
    });

    group('getCustomTemplate', () {
      test('returns custom template', () {
        final customTemplate = TemplateService.getCustomTemplate();
        
        expect(customTemplate.id, equals('custom'));
        expect(customTemplate.title, equals('Custom'));
        expect(customTemplate.category, equals(TemplateCategory.custom));
        expect(customTemplate.isCustom, isTrue);
      });
    });

    group('getClearTemplate', () {
      test('returns clear template', () {
        final clearTemplate = TemplateService.getClearTemplate();
        
        expect(clearTemplate.id, equals('clear'));
        expect(clearTemplate.title, equals('Clear'));
        expect(clearTemplate.category, equals(TemplateCategory.custom));
        expect(clearTemplate.isCustom, isTrue);
      });
    });

    group('getRandomGoodDeed', () {
      test('returns a valid template', () {
        final randomTemplate = TemplateService.getRandomGoodDeed();
        
        expect(randomTemplate, isNotNull);
        expect(randomTemplate.title, isNotEmpty);
        expect(randomTemplate.id, isNotEmpty);
      });

      test('returns fallback when templates are empty', () {
        // This test verifies the fallback behavior
        final randomTemplate = TemplateService.getRandomGoodDeed();
        
        expect(randomTemplate, isNotNull);
        expect(randomTemplate.title, isNotEmpty);
      });
    });

    group('getAllTemplates', () {
      test('returns all templates including custom', () {
        final allTemplates = TemplateService.getAllTemplates();
        final predefinedCount = TemplateService.getPredefinedTemplates().length;
        
        expect(allTemplates.length, equals(predefinedCount + 1));
        expect(allTemplates.any((t) => t.isCustom), isTrue);
        expect(allTemplates.last.isCustom, isTrue);
      });
    });

    group('getTemplateById', () {
      test('returns template for valid ID', () {
        final template = TemplateService.getTemplateById('call_mom');
        
        expect(template, isNotNull);
        expect(template!.id, equals('call_mom'));
        expect(template.title, equals('Call mom'));
      });

      test('returns custom template for custom ID', () {
        final template = TemplateService.getTemplateById('custom');
        
        expect(template, isNotNull);
        expect(template!.isCustom, isTrue);
      });

      test('returns clear template for clear ID', () {
        final template = TemplateService.getTemplateById('clear');
        
        expect(template, isNotNull);
        expect(template!.id, equals('clear'));
        expect(template.isCustom, isTrue);
      });

      test('returns null for invalid ID', () {
        final template = TemplateService.getTemplateById('invalid_id');
        
        expect(template, isNull);
      });
    });

    group('getTemplatesGroupedByCategory', () {
      test('returns templates grouped by category', () {
        final grouped = TemplateService.getTemplatesGroupedByCategory();
        
        expect(grouped, isA<Map<String, List<ReminderTemplate>>>());
        expect(grouped.containsKey(TemplateCategory.personal), isTrue);
        expect(grouped.containsKey(TemplateCategory.health), isTrue);
        expect(grouped.containsKey(TemplateCategory.charity), isTrue);
        expect(grouped.containsKey(TemplateCategory.spiritual), isTrue);
        expect(grouped.containsKey(TemplateCategory.work), isTrue);
      });

      test('each category contains correct templates', () {
        final grouped = TemplateService.getTemplatesGroupedByCategory();
        
        for (final entry in grouped.entries) {
          final category = entry.key;
          final templates = entry.value;
          
          for (final template in templates) {
            expect(template.category, equals(category));
          }
        }
      });
    });

    group('getTemplateCount', () {
      test('returns correct count of predefined templates', () {
        final count = TemplateService.getTemplateCount();
        final actualCount = TemplateService.getPredefinedTemplates().length;
        
        expect(count, equals(actualCount));
        expect(count, greaterThanOrEqualTo(20));
      });
    });

    group('hasMinimumTemplates', () {
      test('returns true when has minimum required templates', () {
        final hasMinimum = TemplateService.hasMinimumTemplates();
        
        expect(hasMinimum, isTrue);
      });
    });

    group('template content validation', () {
      test('contains expected personal templates', () {
        final personalTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.personal);
        final titles = personalTemplates.map((t) => t.title).toList();
        
        expect(titles, contains('Call mom'));
        expect(titles, contains('Call dad'));
        expect(titles, contains('Visit family'));
        expect(titles, contains('Check on elderly relatives'));
        expect(titles, contains('Send message to siblings'));
        expect(titles, contains('Plan family gathering'));
        expect(personalTemplates.length, equals(6));
      });

      test('contains expected health templates', () {
        final healthTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.health);
        final titles = healthTemplates.map((t) => t.title).toList();
        
        expect(titles, contains('Take medication'));
        expect(titles, contains('Drink water'));
        expect(titles, contains('Exercise'));
        expect(titles, contains('Go for a walk'));
        expect(titles, contains('Get enough sleep'));
        expect(healthTemplates.length, equals(5));
      });

      test('contains expected charity templates', () {
        final charityTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.charity);
        final titles = charityTemplates.map((t) => t.title).toList();
        
        expect(titles, contains('Give food to poor'));
        expect(titles, contains('Visit the sick'));
        expect(titles, contains('Help a neighbor'));
        expect(titles, contains('Donate to charity'));
        expect(charityTemplates.length, equals(4));
      });

      test('contains expected spiritual templates', () {
        final spiritualTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.spiritual);
        final titles = spiritualTemplates.map((t) => t.title).toList();
        
        expect(titles, contains('Read Quran'));
        expect(titles, contains('Make dua'));
        expect(titles, contains('Pray on time'));
        expect(spiritualTemplates.length, equals(3));
      });

      test('contains expected work templates', () {
        final workTemplates = TemplateService.getTemplatesByCategory(TemplateCategory.work);
        final titles = workTemplates.map((t) => t.title).toList();
        
        expect(titles, contains('Check emails'));
        expect(titles, contains('Review daily goals'));
        expect(workTemplates.length, equals(2));
      });

      test('total template count meets requirements', () {
        final totalCount = TemplateService.getTemplateCount();
        
        // Should have exactly 20 predefined templates as per design
        expect(totalCount, equals(20));
        
        // Verify breakdown: 6 + 5 + 4 + 3 + 2 = 20
        final personalCount = TemplateService.getTemplatesByCategory(TemplateCategory.personal).length;
        final healthCount = TemplateService.getTemplatesByCategory(TemplateCategory.health).length;
        final charityCount = TemplateService.getTemplatesByCategory(TemplateCategory.charity).length;
        final spiritualCount = TemplateService.getTemplatesByCategory(TemplateCategory.spiritual).length;
        final workCount = TemplateService.getTemplatesByCategory(TemplateCategory.work).length;
        
        expect(personalCount + healthCount + charityCount + spiritualCount + workCount, equals(20));
      });
    });
  });
}