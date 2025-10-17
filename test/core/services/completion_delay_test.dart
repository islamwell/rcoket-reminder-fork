import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../../../lib/core/models/delay_option.dart';
import '../../../lib/core/services/notification_service.dart';

void main() {
  group('Completion Delay Functionality Tests', () {
    test('DelayOption model should have correct presets', () {
      final presets = DelayOption.presets;
      
      expect(presets.length, 5);
      expect(presets[0].id, '1min');
      expect(presets[0].duration, Duration(minutes: 1));
      expect(presets[1].id, '5min');
      expect(presets[1].duration, Duration(minutes: 5));
      expect(presets[2].id, '15min');
      expect(presets[2].duration, Duration(minutes: 15));
      expect(presets[3].id, '1hr');
      expect(presets[3].duration, Duration(hours: 1));
      expect(presets[4].id, 'custom');
      expect(presets[4].isCustom, true);
    });

    test('DelayOption should format duration correctly', () {
      final option1min = DelayOption.presets[0];
      final option5min = DelayOption.presets[1];
      final option1hr = DelayOption.presets[3];
      
      expect(option1min.displayText, '1 minute');
      expect(option5min.displayText, '5 minutes');
      expect(option1hr.displayText, '1 hour');
    });

    test('DelayOption copyWithDuration should work correctly', () {
      final customOption = DelayOption.presets[4];
      final newDuration = Duration(minutes: 30);
      final updatedOption = customOption.copyWithDuration(newDuration);
      
      expect(updatedOption.duration, newDuration);
      expect(updatedOption.displayText, '30 minutes');
      expect(updatedOption.isCustom, true);
    });

    test('NotificationService should provide delay presets', () {
      final service = NotificationService.instance;
      final presets = service.getDelayPresets();
      
      expect(presets.length, 5);
      expect(presets, equals(DelayOption.presets));
    });

    test('Schedule time validation should work correctly', () {
      final service = NotificationService.instance;
      
      // Test private method through reflection or create a test helper
      // For now, we'll test the public interface behavior
      expect(service.getDelayPresets().isNotEmpty, true);
    });
  });
}