import '../models/models.dart';

/// Abstract interface for health data database operations
abstract class HealthDatabase {
  /// Initialize the database and create tables if needed
  Future<void> initialize();

  /// Insert a new health record and return the generated ID
  Future<int> insertHealthRecord(HealthRecord record);

  /// Get all health records ordered by timestamp (most recent first)
  Future<List<HealthRecord>> getAllRecords();

  /// Get health records filtered by type, ordered by timestamp (most recent first)
  Future<List<HealthRecord>> getRecordsByType(HealthMetricType type);

  /// Delete a health record by ID
  Future<void> deleteRecord(int id);

  /// Close the database connection
  Future<void> close();
}