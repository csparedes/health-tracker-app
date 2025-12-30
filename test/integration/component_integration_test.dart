import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/blocs/blocs.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';
import 'package:health_tracker_app/services/services.dart';

/// Test suite to verify all components integrate correctly
void main() {
  group('Component Integration Tests', () {
    late SQLiteHealthDatabase database;
    late LocalHealthRepository repository;
    late HealthTrackingBloc bloc;
    late ConnectivityService connectivityService;
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
      connectivityService = ConnectivityService();
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
    });

    tearDown(() async {
      await bloc.close();
      await database.close();
      connectivityService.dispose();
    });

    group('Database -> Repository -> BLoC Integration', () {
      test('should handle complete data flow from database to BLoC', () async {
        // Test the complete data flow: Database -> Repository -> BLoC -> UI State

        // Step 1: Direct database operation
        final directRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
          notes: 'Direct database insert',
        );

        final recordId = await database.insertHealthRecord(directRecord);
        expect(recordId, greaterThan(0));

        // Step 2: Repository should see the record
        final repositoryRecords = await repository.getHealthHistory();
        expect(repositoryRecords, hasLength(1));
        expect(repositoryRecords.first.value, equals(120.0));

        // Step 3: BLoC should handle the data correctly
        bloc.add(const LoadHistory());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<HealthTrackingLoading>(),
            isA<HealthTrackingLoaded>().having(
              (state) => state.records.length,
              'records length',
              equals(1),
            ),
          ]),
        );

        // Step 4: Add record through BLoC
        final blocRecord = HealthRecord(
          type: HealthMetricType.waistDiameter,
          value: 85.0,
          timestamp: testTimestamp.add(const Duration(hours: 1)),
          notes: 'Added through BLoC',
        );

        bloc.add(AddHealthRecord(blocRecord));
        await expectLater(
          bloc.stream,
          emits(isA<HealthRecordAdded>()),
        );

        // Step 5: Verify database has both records
        final finalRecords = await database.getAllRecords();
        expect(finalRecords, hasLength(2));

        // Step 6: Verify repository consistency
        final finalRepositoryRecords = await repository.getHealthHistory();
        expect(finalRepositoryRecords, hasLength(2));
      });

      test('should handle validation errors across all layers', () async {
        // Test error propagation: Repository -> BLoC -> UI State

        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -50.0, // Invalid negative value
          timestamp: testTimestamp,
          notes: 'Invalid record',
        );

        // Step 1: Repository should reject invalid record
        expect(
          () => repository.saveHealthRecord(invalidRecord),
          throwsA(isA<ValidationException>()),
        );

        // Step 2: BLoC should handle validation error
        bloc.add(AddHealthRecord(invalidRecord));
        await expectLater(
          bloc.stream,
          emits(isA<HealthTrackingValidationError>()),
        );

        // Step 3: Database should remain empty
        final records = await database.getAllRecords();
        expect(records, isEmpty);
      });

      test('should handle concurrent operations correctly', () async {
        // Test concurrent operations across all layers

        final records = List.generate(10, (index) => HealthRecord(
          type: HealthMetricType.values[index % 3],
          value: 100.0 + index,
          timestamp: testTimestamp.add(Duration(minutes: index)),
          notes: 'Concurrent record $index',
        ));

        // Add records concurrently through BLoC
        for (final record in records) {
          bloc.add(AddHealthRecord(record));
        }

        // Wait for all operations to complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Verify all records were saved
        final savedRecords = await repository.getHealthHistory();
        expect(savedRecords, hasLength(10));

        // Verify ordering (most recent first)
        expect(savedRecords.first.notes, equals('Concurrent record 9'));
        expect(savedRecords.last.notes, equals('Concurrent record 0'));
      });
    });

    group('Model -> Database Integration', () {
      test('should handle all model serialization/deserialization correctly', () async {
        // Test all HealthMetricType values
        for (final type in HealthMetricType.values) {
          final record = HealthRecord(
            type: type,
            value: type.validationRange.min + 10, // Valid value within range
            timestamp: testTimestamp.add(Duration(hours: type.index)),
            notes: 'Test ${type.displayName}',
          );

          // Save through repository
          await repository.saveHealthRecord(record);

          // Retrieve and verify
          final typeRecords = await repository.getHistoryByType(type);
          expect(typeRecords, hasLength(1));

          final savedRecord = typeRecords.first;
          expect(savedRecord.type, equals(type));
          expect(savedRecord.value, equals(type.validationRange.min + 10));
          expect(savedRecord.notes, equals('Test ${type.displayName}'));

          // Verify formatting
          expect(savedRecord.formattedValue, contains(type.unit));
          expect(savedRecord.formattedTimestamp, isNotEmpty);
        }
      });

      test('should handle edge cases in model validation', () async {
        // Test boundary values for each metric type
        for (final type in HealthMetricType.values) {
          final range = type.validationRange;

          // Test minimum valid value
          final minRecord = HealthRecord(
            type: type,
            value: range.min,
            timestamp: testTimestamp,
            notes: 'Min value test',
          );

          await repository.saveHealthRecord(minRecord);
          final minRecords = await repository.getHistoryByType(type);
          expect(minRecords.last.value, equals(range.min));

          // Test maximum valid value
          final maxRecord = HealthRecord(
            type: type,
            value: range.max,
            timestamp: testTimestamp.add(const Duration(minutes: 1)),
            notes: 'Max value test',
          );

          await repository.saveHealthRecord(maxRecord);
          final maxRecords = await repository.getHistoryByType(type);
          expect(maxRecords.first.value, equals(range.max));

          // Test just below minimum (should fail)
          final belowMinRecord = HealthRecord(
            type: type,
            value: range.min - 0.1,
            timestamp: testTimestamp,
            notes: 'Below min test',
          );

          expect(
            () => repository.saveHealthRecord(belowMinRecord),
            throwsA(isA<ValidationException>()),
          );

          // Test just above maximum (should fail)
          final aboveMaxRecord = HealthRecord(
            type: type,
            value: range.max + 0.1,
            timestamp: testTimestamp,
            notes: 'Above max test',
          );

          expect(
            () => repository.saveHealthRecord(aboveMaxRecord),
            throwsA(isA<ValidationException>()),
          );
        }
      });
    });

    group('BLoC State Management Integration', () {
      test('should handle all BLoC events and states correctly', () async {
        // Test LoadHistory
        bloc.add(const LoadHistory());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<HealthTrackingLoading>(),
            isA<HealthTrackingLoaded>().having(
              (state) => state.records,
              'records',
              isEmpty,
            ),
          ]),
        );

        // Add a record
        final record = HealthRecord(
          type: HealthMetricType.glucose,
          value: 110.0,
          timestamp: testTimestamp,
          notes: 'BLoC test record',
        );

        bloc.add(AddHealthRecord(record));
        await expectLater(
          bloc.stream,
          emits(isA<HealthRecordAdded>()),
        );

        // Test FilterByType
        bloc.add(const FilterByType(HealthMetricType.glucose));
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<HealthTrackingLoading>(),
            isA<HealthTrackingLoaded>().having(
              (state) => state.records.length,
              'filtered records length',
              equals(1),
            ),
          ]),
        );

        // Test GetRecordCountByType
        bloc.add(const GetRecordCountByType(HealthMetricType.glucose));
        await expectLater(
          bloc.stream,
          emits(isA<RecordCountLoaded>().having(
            (state) => state.count,
            'count',
            equals(1),
          )),
        );

        // Test GetMostRecentRecordByType
        bloc.add(const GetMostRecentRecordByType(HealthMetricType.glucose));
        await expectLater(
          bloc.stream,
          emits(isA<MostRecentRecordLoaded>().having(
            (state) => state.record?.value,
            'most recent value',
            equals(110.0),
          )),
        );
      });

      test('should handle error states correctly', () async {
        // Close database to simulate error
        await database.close();

        // Try to add record (should fail)
        final record = HealthRecord(
          type: HealthMetricType.glucose,
          value: 120.0,
          timestamp: testTimestamp,
          notes: 'Error test',
        );

        bloc.add(AddHealthRecord(record));
        await expectLater(
          bloc.stream,
          emits(isA<HealthTrackingError>()),
        );

        // Try to load history (should fail)
        bloc.add(const LoadHistory());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<HealthTrackingLoading>(),
            isA<HealthTrackingError>(),
          ]),
        );
      });
    });

    group('Service Integration', () {
      test('should integrate connectivity service correctly', () async {
        // Test connectivity service initialization
        expect(connectivityService.isConnected, isFalse); // Default state

        // Start monitoring
        connectivityService.startMonitoring();

        // Wait for initial connectivity check
        await Future.delayed(const Duration(milliseconds: 100));

        // Stop monitoring
        connectivityService.stopMonitoring();

        // Service should handle start/stop correctly
        expect(() => connectivityService.dispose(), returnsNormally);
      });
    });

    group('Complete Integration Scenarios', () {
      test('should handle complete user journey with all components', () async {
        // Scenario: User adds multiple records, views history, filters, and checks recent data

        // Step 1: Add records of all types
        final testRecords = [
          HealthRecord(
            type: HealthMetricType.glucose,
            value: 95.0,
            timestamp: testTimestamp,
            notes: 'Morning fasting glucose',
          ),
          HealthRecord(
            type: HealthMetricType.waistDiameter,
            value: 82.5,
            timestamp: testTimestamp.add(const Duration(hours: 1)),
            notes: 'Weekly measurement',
          ),
          HealthRecord(
            type: HealthMetricType.bodyWeight,
            value: 68.5,
            timestamp: testTimestamp.add(const Duration(hours: 2)),
            notes: 'Daily weigh-in',
          ),
        ];

        // Add through BLoC
        for (final record in testRecords) {
          bloc.add(AddHealthRecord(record));
          await expectLater(
            bloc.stream,
            emits(isA<HealthRecordAdded>()),
          );
        }

        // Step 2: Load complete history
        bloc.add(const LoadHistory());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<HealthTrackingLoading>(),
            isA<HealthTrackingLoaded>().having(
              (state) => state.records.length,
              'total records',
              equals(3),
            ),
          ]),
        );

        // Step 3: Filter by each type
        for (final type in HealthMetricType.values) {
          bloc.add(FilterByType(type));
          await expectLater(
            bloc.stream,
            emitsInOrder([
              isA<HealthTrackingLoading>(),
              isA<HealthTrackingLoaded>().having(
                (state) => state.records.length,
                'filtered records for $type',
                equals(1),
              ),
            ]),
          );
        }

        // Step 4: Get counts and most recent for each type
        for (final type in HealthMetricType.values) {
          bloc.add(GetRecordCountByType(type));
          await expectLater(
            bloc.stream,
            emits(isA<RecordCountLoaded>().having(
              (state) => state.count,
              'count for $type',
              equals(1),
            )),
          );

          bloc.add(GetMostRecentRecordByType(type));
          await expectLater(
            bloc.stream,
            emits(isA<MostRecentRecordLoaded>().having(
              (state) => state.record,
              'most recent for $type',
              isNotNull,
            )),
          );
        }

        // Step 5: Verify database consistency
        final dbRecords = await database.getAllRecords();
        expect(dbRecords, hasLength(3));

        // Step 6: Verify repository consistency
        final repoRecords = await repository.getHealthHistory();
        expect(repoRecords, hasLength(3));

        // Verify ordering (most recent first)
        expect(repoRecords[0].type, equals(HealthMetricType.bodyWeight));
        expect(repoRecords[1].type, equals(HealthMetricType.waistDiameter));
        expect(repoRecords[2].type, equals(HealthMetricType.glucose));
      });

      test('should handle error recovery across all components', () async {
        // Add valid record first
        final validRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 100.0,
          timestamp: testTimestamp,
          notes: 'Valid record',
        );

        bloc.add(AddHealthRecord(validRecord));
        await expectLater(
          bloc.stream,
          emits(isA<HealthRecordAdded>()),
        );

        // Try to add invalid record
        final invalidRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: -50.0,
          timestamp: testTimestamp,
          notes: 'Invalid record',
        );

        bloc.add(AddHealthRecord(invalidRecord));
        await expectLater(
          bloc.stream,
          emits(isA<HealthTrackingValidationError>()),
        );

        // Verify system recovered and valid record is still there
        bloc.add(const LoadHistory());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<HealthTrackingLoading>(),
            isA<HealthTrackingLoaded>().having(
              (state) => state.records.length,
              'records after error',
              equals(1),
            ),
          ]),
        );

        // Add another valid record to verify system is still functional
        final anotherValidRecord = HealthRecord(
          type: HealthMetricType.waistDiameter,
          value: 85.0,
          timestamp: testTimestamp.add(const Duration(hours: 1)),
          notes: 'Recovery test',
        );

        bloc.add(AddHealthRecord(anotherValidRecord));
        await expectLater(
          bloc.stream,
          emits(isA<HealthRecordAdded>()),
        );

        // Final verification
        final finalRecords = await repository.getHealthHistory();
        expect(finalRecords, hasLength(2));
      });
    });
  });
}