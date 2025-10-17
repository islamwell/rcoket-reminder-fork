import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/services/error_handling_service.dart';

void main() {
  group('ErrorHandlingService Fallback Mode Reset', () {
    late ErrorHandlingService errorService;

    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
      errorService = ErrorHandlingService.instance;
    });

    testWidgets('should reset fallback mode when system health is good', (WidgetTester tester) async {
      // Set up initial fallback mode state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fallback_mode', true);
      
      // Initialize the service (this should trigger reset logic)
      await errorService.initialize();
      
      // Verify that fallback mode was reset since there are no critical errors
      expect(errorService.isInFallbackMode, false);
    });

    testWidgets('should generate health report correctly', (WidgetTester tester) async {
      await errorService.initialize();
      
      final healthReport = await errorService.generateHealthReport();
      
      expect(healthReport, isNotNull);
      expect(healthReport.lastHealthCheck, isNotNull);
      expect(healthReport.recommendations, isNotEmpty);
      expect(healthReport.fallbackModeCorrect, true);
    });

    testWidgets('should determine fallback mode necessity correctly', (WidgetTester tester) async {
      await errorService.initialize();
      
      // With no errors, should not be in fallback mode
      final shouldBeFallback = await errorService.shouldBeInFallbackMode();
      expect(shouldBeFallback, false);
    });

    testWidgets('should reset to normal mode when appropriate', (WidgetTester tester) async {
      // Set up fallback mode
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fallback_mode', true);
      
      await errorService.initialize();
      
      // Should reset to normal mode since there are no critical errors
      await errorService.resetToNormalMode();
      expect(errorService.isInFallbackMode, false);
    });
  });
}