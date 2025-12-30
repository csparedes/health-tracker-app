import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';

/// Test suite to verify offline functionality works correctly
void main() {
  group('Offline Functionality Tests', () {
    late SQLiteHealthDatabase database;
    late LocalHealthRepository repository;
    late HealthTrackingBloc bloc;
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
      bloc = HealthTrackingBloc(repository);
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    tearDown(() async {
      await bloc.close();
      await database.close();
    });

    group('Data Entry Without Network', () {
      test('should save health records without network connectivity', () async {
        // Simulate offline environment by using local-only operations
        final glucoseRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.5,
          timestamp: testTimestamp,
          notes: 'Offline entry test',
        );

        final waistRecord = HealthRecord(
          type: HealthMetricType.waistDiameter,
          value: 85.0,
          timestamp: testTimestamp.add(const Duration(minutes: 30)),
          notes: 'Offline waist measurement',
        );

        final weightRecord = HealthRecord(
          type: HealthMetricType.bodyWeight,
          value: 70.5,
          timestamp: testTimestamp.add(const Duration(hours: 1)),
          notes: 'Offline weight measurement',
        );

        // Save records (should work without network)
        await repository.saveHealthRecord(glucoseRecord);
        await repository.saveHealthRecord(waistRecord);
        await repository.saveHealthRecord(weightRecord);

        // Verify all records were saved
        final allRecords = await repository.getHealthHistory();
        expect(allRecords, hasLength(3));

        // Verify records are ordered correctly (most recent first)
        expect(allRecords[0].type, equals(HealthMetricType.bodyWeight));
        expect(allRecords[1].type, equals(HealthMetricType.waistDiameter));
        expect(allRecords[2].type, equals(HealthMetricType.glucose));

        // Verify record content
        expect(allRecords[2].value, equals(120.5));
        expect(allRecords[2].notes, equals('Offline entry test'));
      });

      test('should validate data correctly in offline mode', () async {
        // Test validation works without network
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -10.0, // Invalid negative value
          timestamp: testTimestamp,
          notes: 'Invalid offline test',
        );

        // Should throw validation exception
        expect(
          () => repository.saveHealthRecord(invalidRecord),
          throwsA(isA<ValidationException>()),
        );

        // Verify no records were saved
        final allRecords = await repository.getHealthHistory();
        expect(allRecords, isEmpty);
      });

      test('should handle out-of-range values in offline mode', () async {
        final outOfRangeRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 1500.0, // Above max range
          timestamp: testTimestamp,
          notes: 'Out of range offline test',
        );

        // Should throw validation exception
        expect(
          () => repository.saveHealthRecord(outOfRangeRecord),
          throwsA(isA<ValidationException>()),
        );

        // Verify no records were saved
        final allRecords = await repository.getHealthHistory();
        expect(allRecords, isEmpty);
      });
    });

    group('Data Viewing Without Network', () {
      test('should retrieve and display data without network connectivity', () async {
        // First, add some test data
        final testRecords = [
          HealthRecord(
            type: HealthMetricType.glucose,
            value: 110.0,
            timestamp: testTimestamp,
            notes: 'Morning reading',
          ),
          HealthRecord(
            type: HealthMetricType.waistDiameter,
            value: 82.5,
            timestamp: testTimestamp.add(const Duration(hours: 1)),
            notes: 'After breakfast',
          ),
          HealthRecord(
            type: HealthMetricType.bodyWeight,
            value: 68.0,
            timestamp: testTimestamp.add(const Duration(hours: 2)),
            notes: 'Daily weigh-in',
          ),
        ];

        for (final record in testRecords) {
          await repository.saveHealthRecord(record);
        }

        // Test retrieving all records (should work offline)
        final allRecords = await repository.getHealthHistory();
        expect(allRecords, hasLength(3));

        // Test filtering by type (should work offline)
        final glucoseRecords = await repository.getHistoryByType(HealthMetricType.glucose);
        expect(glucoseRecords, hasLength(1));
        expect(glucoseRecords.first.value, equals(110.0));

        final waistRecords = await repository.getHistoryByType(HealthMetricType.waistDiameter);
        expect(waistRecords, hasLength(1));
        expect(waistRecords.first.value, equals(82.5));

        final weightRecords = await repository.getHistoryByType(HealthMetricType.bodyWeight);
        expect(weightRecords, hasLength(1));
        expect(weightRecords.first.value, equals(68.0));

        // Test record counts (should work offline)
        final glucoseCount = await repository.getRecordCountByType(HealthMetricType.glucose);
        expect(glucoseCount, equals(1));

        final waistCount = await repository.getRecordCountByType(HealthMetricType.waistDiameter);
        expect(waistCount, equals(1));

        final weightCount = await repository.getRecordCountByType(HealthMetricType.bodyWeight);
        expect(weightCount, equals(1));

        // Test most recent records (should work offline)
        final mostRecentGlucose = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
        expect(mostRecentGlucose, isNotNull);
        expect(mostRecentGlucose!.value, equals(110.0));
      });

      test('should handle empty database in offline mode', () async {
        // Test empty database queries work offline
        final emptyHistory = await repository.getHealthHistory();
        expect(emptyHistory, isEmpty);

        final emptyGlucoseHistory = await repository.getHistoryByType(HealthMetricType.glucose);
        expect(emptyGlucoseHistory, isEmpty);

        final zeroCount = await repository.getRecordCountByType(HealthMetricType.glucose);
        expect(zeroCount, equals(0));

        final nullMostRecent = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
        expect(nullMostRecent, isNull);
      });
    });

    group('Database Operations Without Network', () {
      test('should handle database transactions in offline mode', () async {
        // Test that database transactions work without network
        final record1 = HealthRecord(
          type: HealthMetricType.glucose,
          value: 95.0,
          timestamp: testTimestamp,
          notes: 'Transaction test 1',
        );

        final record2 = HealthRecord(
          type: HealthMetricType.glucose,
          value: 105.0,
          timestamp: testTimestamp.add(const Duration(minutes: 30)),
          notes: 'Transaction test 2',
        );

        // Save multiple records (each should be in its own transaction)
        await repository.saveHealthRecord(record1);
        await repository.saveHealthRecord(record2);

        // Verify both records were saved
        final glucoseRecords = await repository.getHistoryByType(HealthMetricType.glucose);
        expect(glucoseRecords, hasLength(2));

        // Verify ordering (most recent first)
        expect(glucoseRecords[0].value, equals(105.0));
        expect(glucoseRecords[1].value, equals(95.0));
      });

      test('should handle date range queries in offline mode', () async {
        // Add records across different dates
        final records = [
          HealthRecord(
            type: HealthMetricType.glucose,
            value: 100.0,
            timestamp: DateTime(2024, 1, 10, 9, 0),
            notes: 'Day 1',
          ),
          HealthRecord(
            type: HealthMetricType.glucose,
            value: 110.0,
            timestamp: DateTime(2024, 1, 15, 9, 0),
            notes: 'Day 2',
          ),
          HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: DateTime(2024, 1, 20, 9, 0),
            notes: 'Day 3',
          ),
        ];

        for (final record in records) {
          await repository.saveHealthRecord(record);
        }

        // Test date range query (should work offline)
        final rangeRecords = await repository.getRecordsByDateRange(
          DateTime(2024, 1, 12),
          DateTime(2024, 1, 18),
          type: HealthMetricType.glucose,
        );

        expect(rangeRecords, hasLength(1));
        expect(rangeRecords.first.value, equals(110.0));
        expect(rangeRecords.first.notes, equals('Day 2'));
      });
    });

    group('Error Handling in Offline Mode', () {
      test('should provide meaningful error messages in offline mode', () async {
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -50.0,
          timestamp: testTimestamp,
        );

        try {
          await repository.saveHealthRecord(invalidRecord);
          fail('Should have thrown ValidationException');
        } catch (e) {
          expect(e, isA<ValidationException>());
          final validationError = e as ValidationException;
          expect(validationError.message, contains('El valor debe ser mayor que cero'));
        }
      });

      test('should handle database errors gracefully in offline mode', () async {
        // Close the database to simulate a database error
        await database.close();

        final record = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
        );

        // Should throw RepositoryException
        expect(
          () => repository.saveHealthRecord(record),
          throwsA(isA<RepositoryException>()),
        );
      });
    });
  });
}