import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:health_tracker_app/database/database.dart';
import 'package:health_tracker_app/models/models.dart';
import 'package:health_tracker_app/repositories/repositories.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

/// Test suite to verify session persistence across app restarts
void main() {
  group('Session Persistence Tests', () {
    late String testDbPath;
    late DateTime testTimestamp;

    setUpAll(() {
      // Initialize FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      testTimestamp = DateTime(2024, 1, 15, 10, 30);
      // Create a unique test database path for each test
      testDbPath = path.join(Directory.systemTemp.path, 'test_health_${DateTime.now().millisecondsSinceEpoch}.db');
    });

    tearDown(() async {
      // Clean up test database file
      try {
        final file = File(testDbPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Data Persistence Across Sessions', () {
      test('should persist data between app restarts', () async {
        // Session 1: Create database, add data, close
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Add test data
          final testRecords = [
            HealthRecord(
              type: HealthMetricType.glucose,
              value: 125.5,
              timestamp: testTimestamp,
              notes: 'Session 1 - Morning reading',
            ),
            HealthRecord(
              type: HealthMetricType.waistDiameter,
              value: 88.0,
              timestamp: testTimestamp.add(const Duration(hours: 1)),
              notes: 'Session 1 - After breakfast',
            ),
            HealthRecord(
              type: HealthMetricType.bodyWeight,
              value: 72.3,
              timestamp: testTimestamp.add(const Duration(hours: 2)),
              notes: 'Session 1 - Daily weigh-in',
            ),
          ];

          for (final record in testRecords) {
            await repository.saveHealthRecord(record);
          }

          // Verify data was saved
          final savedRecords = await repository.getHealthHistory();
          expect(savedRecords, hasLength(3));

          // Close database (simulate app shutdown)
          await database.close();
        }

        // Session 2: Reopen database, verify data persists
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Verify all data persisted
          final persistedRecords = await repository.getHealthHistory();
          expect(persistedRecords, hasLength(3));

          // Verify record details
          expect(persistedRecords[0].type, equals(HealthMetricType.bodyWeight));
          expect(persistedRecords[0].value, equals(72.3));
          expect(persistedRecords[0].notes, equals('Session 1 - Daily weigh-in'));

          expect(persistedRecords[1].type, equals(HealthMetricType.waistDiameter));
          expect(persistedRecords[1].value, equals(88.0));
          expect(persistedRecords[1].notes, equals('Session 1 - After breakfast'));

          expect(persistedRecords[2].type, equals(HealthMetricType.glucose));
          expect(persistedRecords[2].value, equals(125.5));
          expect(persistedRecords[2].notes, equals('Session 1 - Morning reading'));

          // Add more data in session 2
          final newRecord = HealthRecord(
            type: HealthMetricType.glucose,
            value: 95.0,
            timestamp: testTimestamp.add(const Duration(hours: 3)),
            notes: 'Session 2 - Afternoon reading',
          );

          await repository.saveHealthRecord(newRecord);

          // Verify total count
          final allRecords = await repository.getHealthHistory();
          expect(allRecords, hasLength(4));

          await database.close();
        }

        // Session 3: Verify all data from both sessions persists
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          final finalRecords = await repository.getHealthHistory();
          expect(finalRecords, hasLength(4));

          // Verify we have records from both sessions
          final glucoseRecords = await repository.getHistoryByType(HealthMetricType.glucose);
          expect(glucoseRecords, hasLength(2));

          // Most recent glucose record should be from session 2
          expect(glucoseRecords[0].value, equals(95.0));
          expect(glucoseRecords[0].notes, equals('Session 2 - Afternoon reading'));

          // Older glucose record should be from session 1
          expect(glucoseRecords[1].value, equals(125.5));
          expect(glucoseRecords[1].notes, equals('Session 1 - Morning reading'));

          await database.close();
        }
      });

      test('should maintain data integrity across multiple sessions', () async {
        // Session 1: Add initial data
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Add 10 records across different types
          for (int i = 0; i < 10; i++) {
            final type = HealthMetricType.values[i % 3];
            final record = HealthRecord(
              type: type,
              value: 100.0 + i,
              timestamp: testTimestamp.add(Duration(minutes: i * 10)),
              notes: 'Session 1 - Record $i',
            );
            await repository.saveHealthRecord(record);
          }

          await database.close();
        }

        // Session 2: Verify and add more data
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Verify initial data
          final initialRecords = await repository.getHealthHistory();
          expect(initialRecords, hasLength(10));

          // Add 5 more records
          for (int i = 10; i < 15; i++) {
            final type = HealthMetricType.values[i % 3];
            final record = HealthRecord(
              type: type,
              value: 100.0 + i,
              timestamp: testTimestamp.add(Duration(minutes: i * 10)),
              notes: 'Session 2 - Record $i',
            );
            await repository.saveHealthRecord(record);
          }

          await database.close();
        }

        // Session 3: Final verification
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          final allRecords = await repository.getHealthHistory();
          expect(allRecords, hasLength(15));

          // Verify record counts by type
          final glucoseCount = await repository.getRecordCountByType(HealthMetricType.glucose);
          final waistCount = await repository.getRecordCountByType(HealthMetricType.waistDiameter);
          final weightCount = await repository.getRecordCountByType(HealthMetricType.bodyWeight);

          expect(glucoseCount, equals(5)); // Records 0, 3, 6, 9, 12
          expect(waistCount, equals(5));   // Records 1, 4, 7, 10, 13
          expect(weightCount, equals(5));  // Records 2, 5, 8, 11, 14

          // Verify most recent records
          final mostRecentGlucose = await repository.getMostRecentRecordByType(HealthMetricType.glucose);
          expect(mostRecentGlucose?.notes, equals('Session 2 - Record 12'));

          await database.close();
        }
      });
    });

    group('Database Initialization Tests', () {
      test('should initialize database correctly on first launch', () async {
        // Ensure database file doesn't exist
        final file = File(testDbPath);
        if (await file.exists()) {
          await file.delete();
        }

        // Initialize database for first time
        final database = SQLiteHealthDatabase(customPath: testDbPath);
        await database.initialize();

        // Verify database file was created
        expect(await file.exists(), isTrue);

        // Verify database is empty but functional
        final repository = LocalHealthRepository(database);
        final emptyRecords = await repository.getHealthHistory();
        expect(emptyRecords, isEmpty);

        // Verify we can add data
        final testRecord = HealthRecord(
          type: HealthMetricType.glucose,
          value: 110.0,
          timestamp: testTimestamp,
          notes: 'First launch test',
        );

        await repository.saveHealthRecord(testRecord);

        // Verify data was saved
        final savedRecords = await repository.getHealthHistory();
        expect(savedRecords, hasLength(1));
        expect(savedRecords.first.notes, equals('First launch test'));

        await database.close();
      });

      test('should handle subsequent database initializations correctly', () async {
        // First initialization
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Add some data
          final record = HealthRecord(
            type: HealthMetricType.glucose,
            value: 120.0,
            timestamp: testTimestamp,
            notes: 'Initial data',
          );
          await repository.saveHealthRecord(record);

          await database.close();
        }

        // Second initialization (simulate app restart)
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize(); // Should not recreate tables or lose data
          final repository = LocalHealthRepository(database);

          // Verify existing data is still there
          final existingRecords = await repository.getHealthHistory();
          expect(existingRecords, hasLength(1));
          expect(existingRecords.first.notes, equals('Initial data'));

          // Verify we can still add new data
          final newRecord = HealthRecord(
            type: HealthMetricType.waistDiameter,
            value: 85.0,
            timestamp: testTimestamp.add(const Duration(hours: 1)),
            notes: 'Second initialization',
          );
          await repository.saveHealthRecord(newRecord);

          final allRecords = await repository.getHealthHistory();
          expect(allRecords, hasLength(2));

          await database.close();
        }

        // Third initialization
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Verify all data persists
          final finalRecords = await repository.getHealthHistory();
          expect(finalRecords, hasLength(2));

          await database.close();
        }
      });

      test('should handle database schema correctly across sessions', () async {
        // Initialize database and verify schema
        final database = SQLiteHealthDatabase(customPath: testDbPath);
        await database.initialize();

        // Verify we can perform all expected operations
        final repository = LocalHealthRepository(database);

        // Test all CRUD operations
        final testRecord = HealthRecord(
          type: HealthMetricType.bodyWeight,
          value: 70.0,
          timestamp: testTimestamp,
          notes: 'Schema test',
        );

        // Create
        await repository.saveHealthRecord(testRecord);

        // Read
        final records = await repository.getHealthHistory();
        expect(records, hasLength(1));
        final savedRecord = records.first;

        // Verify all fields are properly stored and retrieved
        expect(savedRecord.type, equals(HealthMetricType.bodyWeight));
        expect(savedRecord.value, equals(70.0));
        expect(savedRecord.timestamp, equals(testTimestamp));
        expect(savedRecord.notes, equals('Schema test'));
        expect(savedRecord.id, isNotNull);

        // Test filtering
        final weightRecords = await repository.getHistoryByType(HealthMetricType.bodyWeight);
        expect(weightRecords, hasLength(1));

        // Test counting
        final count = await repository.getRecordCountByType(HealthMetricType.bodyWeight);
        expect(count, equals(1));

        // Test most recent
        final mostRecent = await repository.getMostRecentRecordByType(HealthMetricType.bodyWeight);
        expect(mostRecent, isNotNull);
        expect(mostRecent!.value, equals(70.0));

        await database.close();
      });
    });

    group('Error Recovery Tests', () {
      test('should recover gracefully from corrupted session state', () async {
        // Create database with data
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          final record = HealthRecord(
            type: HealthMetricType.glucose,
            value: 100.0,
            timestamp: testTimestamp,
            notes: 'Before corruption',
          );
          await repository.saveHealthRecord(record);

          await database.close();
        }

        // Simulate app restart after unexpected shutdown
        {
          final database = SQLiteHealthDatabase(customPath: testDbPath);
          await database.initialize();
          final repository = LocalHealthRepository(database);

          // Verify data survived
          final records = await repository.getHealthHistory();
          expect(records, hasLength(1));
          expect(records.first.notes, equals('Before corruption'));

          // Verify app continues to function normally
          final newRecord = HealthRecord(
            type: HealthMetricType.glucose,
            value: 110.0,
            timestamp: testTimestamp.add(const Duration(hours: 1)),
            notes: 'After recovery',
          );
          await repository.saveHealthRecord(newRecord);

          final allRecords = await repository.getHealthHistory();
          expect(allRecords, hasLength(2));

          await database.close();
        }
      });
    });
  });
}