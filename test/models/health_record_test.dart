import 'package:flutter_test/flutter_test.dart';
import 'package:health_tracker_app/models/models.dart';

void main() {
  group('HealthRecord', () {
    late DateTime testTimestamp;
    
    setUp(() {
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    test('should create a valid HealthRecord', () {
      final record = HealthRecord(
        id: 1,
        type: HealthMetricType.glucose,
        value: 120.5,
        timestamp: testTimestamp,
        notes: 'Test note',
      );

      expect(record.id, equals(1));
      expect(record.type, equals(HealthMetricType.glucose));
      expect(record.value, equals(120.5));
      expect(record.timestamp, equals(testTimestamp));
      expect(record.notes, equals('Test note'));
    });

    test('should convert to and from Map correctly', () {
      final record = HealthRecord(
        id: 1,
        type: HealthMetricType.waistDiameter,
        value: 85.0,
        timestamp: testTimestamp,
        notes: 'Test note',
      );

      final map = record.toMap();
      final reconstructed = HealthRecord.fromMap(map);

      expect(reconstructed, equals(record));
    });

    test('should validate correctly for valid values', () {
      final validRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(validRecord.isValid(), isTrue);
    });

    test('should reject negative values', () {
      final invalidRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: -10.0,
        timestamp: DateTime.now(),
      );

      expect(invalidRecord.isValid(), isFalse);
    });

    test('should reject values outside valid range', () {
      final invalidRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 1500.0, // Above max range of 1000
        timestamp: DateTime.now(),
      );

      expect(invalidRecord.isValid(), isFalse);
    });

    test('should reject future timestamps', () {
      final futureRecord = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(futureRecord.isValid(), isFalse);
    });

    test('should format value with units correctly', () {
      final record = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.5,
        timestamp: testTimestamp,
      );

      expect(record.formattedValue, equals('120.5 mg/dL'));
    });

    test('should format timestamp correctly', () {
      final record = HealthRecord(
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      expect(record.formattedTimestamp, equals('15/1/2024 10:30'));
    });

    test('should create copy with modified fields', () {
      final original = HealthRecord(
        id: 1,
        type: HealthMetricType.glucose,
        value: 120.0,
        timestamp: testTimestamp,
        notes: 'Original note',
      );

      final copy = original.copyWith(
        value: 130.0,
        notes: 'Updated note',
      );

      expect(copy.id, equals(original.id));
      expect(copy.type, equals(original.type));
      expect(copy.value, equals(130.0));
      expect(copy.timestamp, equals(original.timestamp));
      expect(copy.notes, equals('Updated note'));
    });
  });
}