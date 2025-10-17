import 'package:flutter_test/flutter_test.dart';
import 'package:good_deeds_reminder/core/models/reminder_template.dart';

void main() {
  group('ReminderTemplate', () {
    group('constructor and validation', () {
      test('creates valid template with required fields', () {
        const template = ReminderTemplate(
          id: 'test_id',
          title: 'Test Template',
          category: 'personal',
        );

        expect(template.id, equals('test_id'));
        expect(template.title, equals('Test Template'));
        expect(template.category, equals('personal'));
        expect(template.isCustom, isFalse);
        expect(template.isValid(), isTrue);
      });

      test('creates valid template with custom flag', () {
        const template = ReminderTemplate(
          id: 'custom_id',
          title: 'Custom Template',
          category: 'custom',
          isCustom: true,
        );

        expect(template.isCustom, isTrue);
        expect(template.isValid(), isTrue);
      });

      test('validates template correctly', () {
        // Valid template
        const validTemplate = ReminderTemplate(
          id: 'valid_id',
          title: 'Valid Title',
          category: 'health',
        );
        expect(validTemplate.isValid(), isTrue);

        // Empty ID
        const emptyIdTemplate = ReminderTemplate(
          id: '',
          title: 'Valid Title',
          category: 'health',
        );
        expect(emptyIdTemplate.isValid(), isFalse);

        // Empty title
        const emptyTitleTemplate = ReminderTemplate(
          id: 'valid_id',
          title: '',
          category: 'health',
        );
        expect(emptyTitleTemplate.isValid(), isFalse);

        // Empty category
        const emptyCategoryTemplate = ReminderTemplate(
          id: 'valid_id',
          title: 'Valid Title',
          category: '',
        );
        expect(emptyCategoryTemplate.isValid(), isFalse);
      });
    });

    group('equality and hashCode', () {
      test('equal templates have same hashCode', () {
        const template1 = ReminderTemplate(
          id: 'test_id',
          title: 'Test Template',
          category: 'personal',
        );

        const template2 = ReminderTemplate(
          id: 'test_id',
          title: 'Test Template',
          category: 'personal',
        );

        expect(template1, equals(template2));
        expect(template1.hashCode, equals(template2.hashCode));
      });

      test('different templates are not equal', () {
        const template1 = ReminderTemplate(
          id: 'test_id_1',
          title: 'Test Template',
          category: 'personal',
        );

        const template2 = ReminderTemplate(
          id: 'test_id_2',
          title: 'Test Template',
          category: 'personal',
        );

        expect(template1, isNot(equals(template2)));
      });

      test('templates with different custom flags are not equal', () {
        const template1 = ReminderTemplate(
          id: 'test_id',
          title: 'Test Template',
          category: 'personal',
          isCustom: false,
        );

        const template2 = ReminderTemplate(
          id: 'test_id',
          title: 'Test Template',
          category: 'personal',
          isCustom: true,
        );

        expect(template1, isNot(equals(template2)));
      });
    });

    group('toString', () {
      test('returns correct string representation', () {
        const template = ReminderTemplate(
          id: 'test_id',
          title: 'Test Template',
          category: 'personal',
          isCustom: true,
        );

        final result = template.toString();
        expect(result, equals('ReminderTemplate(id: test_id, title: Test Template, category: personal, isCustom: true)'));
      });
    });
  });

  group('TemplateCategory', () {
    test('validates categories correctly', () {
      expect(TemplateCategory.isValid(TemplateCategory.personal), isTrue);
      expect(TemplateCategory.isValid(TemplateCategory.health), isTrue);
      expect(TemplateCategory.isValid(TemplateCategory.charity), isTrue);
      expect(TemplateCategory.isValid(TemplateCategory.spiritual), isTrue);
      expect(TemplateCategory.isValid(TemplateCategory.work), isTrue);
      expect(TemplateCategory.isValid(TemplateCategory.custom), isTrue);
      expect(TemplateCategory.isValid('invalid_category'), isFalse);
    });

    test('returns valid categories list', () {
      final validCategories = TemplateCategory.validCategories;
      expect(validCategories, contains(TemplateCategory.personal));
      expect(validCategories, contains(TemplateCategory.health));
      expect(validCategories, contains(TemplateCategory.charity));
      expect(validCategories, contains(TemplateCategory.spiritual));
      expect(validCategories, contains(TemplateCategory.work));
      expect(validCategories, contains(TemplateCategory.custom));
      expect(validCategories.length, equals(6));
    });

    test('validCategories list is unmodifiable', () {
      final validCategories = TemplateCategory.validCategories;
      expect(() => validCategories.add('new_category'), throwsUnsupportedError);
    });
  });
}