import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker_app/models/models.dart';

void main() {
  group('HealthMetricType', () {
    test('should have correct display names in Spanish', () {
      expect(HealthMetricType.glucose.displayName, equals('Glucosa'));
      expect(HealthMetricType.waistDiameter.displayName, equals('Diámetro de Cintura'));
      expect(HealthMetricType.bodyWeight.displayName, equals('Peso Corporal'));
    });

    test('should have correct units', () {
      expect(HealthMetricType.glucose.unit, equals('mg/dL'));
      expect(HealthMetricType.waistDiameter.unit, equals('cm'));
      expect(HealthMetricType.bodyWeight.unit, equals('kg'));
    });

    test('should have correct validation ranges', () {
      final glucoseRange = HealthMetricType.glucose.validationRange;
      expect(glucoseRange.min, equals(0.0));
      expect(glucoseRange.max, equals(1000.0));

      final waistRange = HealthMetricType.waistDiameter.validationRange;
      expect(waistRange.min, equals(10.0));
      expect(waistRange.max, equals(300.0));

      final weightRange = HealthMetricType.bodyWeight.validationRange;
      expect(weightRange.min, equals(1.0));
      expect(weightRange.max, equals(1000.0));
    });

    test('should convert from string correctly', () {
      expect(HealthMetricType.fromString('glucose'), equals(HealthMetricType.glucose));
      expect(HealthMetricType.fromString('waistdiameter'), equals(HealthMetricType.waistDiameter));
      expect(HealthMetricType.fromString('bodyweight'), equals(HealthMetricType.bodyWeight));
    });

    test('should throw error for invalid string', () {
      expect(() => HealthMetricType.fromString('invalid'), throwsArgumentError);
    });

    test('should convert to database string correctly', () {
      expect(HealthMetricType.glucose.toDbString(), equals('glucose'));
      expect(HealthMetricType.waistDiameter.toDbString(), equals('waistDiameter'));
      expect(HealthMetricType.bodyWeight.toDbString(), equals('bodyWeight'));
    });

    test('should handle case insensitive string conversion', () {
      expect(HealthMetricType.fromString('GLUCOSE'), equals(HealthMetricType.glucose));
      expect(HealthMetricType.fromString('WaistDiameter'), equals(HealthMetricType.waistDiameter));
      expect(HealthMetricType.fromString('BodyWeight'), equals(HealthMetricType.bodyWeight));
    });
  });
}