import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';

void main() {
  group('LocalHealthRepository', () {
    late LocalHealthRepository repository;
    late SQLiteHealthDatabase database;
    late DateTime testTimestamp;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Create a new in-memory database for each test
      database = SQLiteHealthDatabase(customPath: ':memory:');
      await database.initialize();
      repository = LocalHealthRepository(database);
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    tearDown(() async {
      await database.close();
    });

    group('saveHealthRecord', () {
      test('should save valid health record successfully', () async {
        final record = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.5,
          timestamp: testTimestamp,
          notes: 'Test glucose reading',
        );

        await repository.saveHealthRecord(record);

        final history = await repository.getHealthHistory();
        expect(history, hasLength(1));
        expect(history.first.type, equals(record.type));
        expect(history.first.value, equals(record.value));
      });

      test('should throw ValidationException for invalid record (negative value)', () async {
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -10.0,
          timestamp: testTimestamp,
        );

        expect(
          () => repository.saveHealthRecord(invalidRecord),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ValidationException for invalid record (out of range)', () async {
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 1500.0, // Above max range of 1000
          timestamp: testTimestamp,
        );

        expect(
          () => repository.saveHealthRecord(invalidRecord),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ValidationException for future timestamp', () async {
        final futureRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: DateTime.now().add(const Duration(hours: 1)),
        );

        expect(
          () => repository.saveHealthRecord(futureRecord),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should provide detailed validation error message in Spanish', () async {
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -10.0,
          timestamp: testTimestamp,
        );

        try {
          await repository.saveHealthRecord(invalidRecord);
          fail('Expected ValidationException');
        } catch (e) {
          expect(e, isA<ValidationException>());
          expect(e.toString(), contains('El valor debe ser mayor que cero'));
        }
      });
    });

    group('getHealthHistory', () {
      test('should return empty list when no records exist', () async {
        final history = await repository.getHealthHistory();
        expect(history, isEmpty);
      });

      test('should return all records ordered by timestamp (most recent first)', () async {
        final oldRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 100.0,
          timestamp: testTimestamp.subtract(const Duration(hours: 2)),
        );

        final newRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        await repository.saveHealthRecord(oldRecord);
        await repository.saveHealthRecord(newRecord);

        final history = await repository.getHealthHistory();
        expect(history, hasLength(2));
        expect(history.first.timestamp, equals(newRecord.timestamp));
        expect(history.last.timestamp, equals(oldRecord.timestamp));
      });
    });

    group('getHistoryByType', () {
      test('should return empty list when no records exist for type', () async {
        final history = await repository.getHistoryByType(HealthMetricType.glucose);
        expect(history, isEmpty);
      });

      test('should return only records of specified type', () async {
        final glucoseRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        final weightRecord = HealthRecord(
          type: HealthMetricType.bodyWeight,
          value: 70.0,
          timestamp: testTimestamp.add(const Duration(minutes: 30)),
        );

        await repository.saveHealthRecord(glucoseRecord);
        await repository.saveHealthRecord(weightRecord);

        final glucoseHistory = await repository.getHistoryByType(HealthMetricType.glucose);
        expect(glucoseHistory, hasLength(1));
        expect(glucoseHistory.first.type, equals(HealthMetricType.glucose));

        final weightHistory = await repository.getHistoryByType(HealthMetricType.bodyWeight);
        expect(weightHistory, hasLength(1));
        expect(weightHistory.first.type, equals(HealthMetricType.bodyWeight));
      });
    });

    group('getRecordCountByType', () {
      test('should return 0 when no records exist for type', () async {
        final count = await repository.getRecordCountByType(HealthMetricType.glucose);
        expect(count, equals(0));
      });

      test('should return correct count for each type', () async {
        await repository.saveHealthRecord(HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        ));

        await repository.saveHealthRecord(HealthRecord(
          type: HealthMetricType.glucose,
          value: 130.0,
          timestamp: testTimestamp.add(const Duration(hours: 1)),
        ));

        await repository.saveHealthRecord(HealthRecord(
          type: HealthMetricType.bodyWeight,
          value: 70.0,
          timestamp: testTimestamp,
        ));

        final glucoseCount = await repository.getRecordCountByType(HealthMetricType.glucose);
        expect(glucoseCount, equals(2));

        final weightCount = await repository.getRecordCountByType(HealthMetricType.bodyWeight);
        expect(weightCount, equals(1));

        final waistCount = await repository.getRecordCountByType(HealthMetricType.waistDiameter);
        expect(waistCount, equals(0));
      });
    });

    group('getMostRecentRecordByType', () {
      test('should return null when no records exist for type', () async {
        final mostRecent = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
        expect(mostRecent, isNull);
      });

      test('should return most recent record for type', () async {
        final oldRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 100.0,
          timestamp: testTimestamp.subtract(const Duration(hours: 2)),
        );

        final newRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        await repository.saveHealthRecord(oldRecord);
        await repository.saveHealthRecord(newRecord);

        final mostRecent = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
        expect(mostRecent, isNotNull);
        expect(mostRecent!.value, equals(120.0));
        expect(mostRecent.timestamp, equals(testTimestamp));
      });
    });

    group('getRecordsByDateRange', () {
      test('should return records within date range', () async {
        final record1 = HealthRecord(
          type: HealthMetricType.glucose,
          value: 100.0,
          timestamp: DateTime(2024, 1, 10),
        );

        final record2 = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: DateTime(2024, 1, 15),
        );

        final record3 = HealthRecord(
          type: HealthMetricType.glucose,
          value: 140.0,
          timestamp: DateTime(2024, 1, 20),
        );

        await repository.saveHealthRecord(record1);
        await repository.saveHealthRecord(record2);
        await repository.saveHealthRecord(record3);

        final records = await repository.getRecordsByDateRange(
          DateTime(2024, 1, 12),
          DateTime(2024, 1, 18),
        );

        expect(records, hasLength(1));
        expect(records.first.value, equals(120.0));
      });

      test('should filter by type within date range', () async {
        final glucoseRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: DateTime(2024, 1, 15),
        );

        final weightRecord = HealthRecord(
          type: HealthMetricType.bodyWeight,
          value: 70.0,
          timestamp: DateTime(2024, 1, 15),
        );

        await repository.saveHealthRecord(glucoseRecord);
        await repository.saveHealthRecord(weightRecord);

        final glucoseRecords = await repository.getRecordsByDateRange(
          DateTime(2024, 1, 12),
          DateTime(2024, 1, 18),
          type: HealthMetricType.glucose,
        );

        expect(glucoseRecords, hasLength(1));
        expect(glucoseRecords.first.type, equals(HealthMetricType.glucose));
      });
    });

    group('deleteRecord', () {
      test('should delete record successfully', () async {
        final record = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        await repository.saveHealthRecord(record);
        var history = await repository.getHealthHistory();
        expect(history, hasLength(1));

        final recordId = history.first.id!;
        await repository.deleteRecord(recordId);

        history = await repository.getHealthHistory();
        expect(history, isEmpty);
      });
    });

    group('validation helpers', () {
      test('validateHealthRecord should return empty list for valid record', () {
        final validRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        final errors = repository.validateHealthRecord(validRecord);
        expect(errors, isEmpty);
      });

      test('validateHealthRecord should return errors for invalid record', () {
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -10.0,
          timestamp: DateTime.now().add(const Duration(hours: 1)),
        );

        final errors = repository.validateHealthRecord(invalidRecord);
        expect(errors, isNotEmpty);
        expect(errors, contains('El valor debe ser mayor que cero'));
        expect(errors, contains('La fecha no puede ser en el futuro'));
      });

      test('isValidHealthRecord should return true for valid record', () {
        final validRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        expect(repository.isValidHealthRecord(validRecord), isTrue);
      });

      test('isValidHealthRecord should return false for invalid record', () {
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -10.0,
          timestamp: testTimestamp,
        );

        expect(repository.isValidHealthRecord(invalidRecord), isFalse);
      });
    });
  });
}