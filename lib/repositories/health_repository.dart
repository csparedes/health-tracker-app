import '../models/models.dart';

/// Abstract interface for health data repository operations
abstract class HealthRepository {
  /// Save a health record with validation
  /// Throws [ValidationException] if the record is invalid
  /// Throws [RepositoryException] if the save operation fails
  Future<void> saveHealthRecord(HealthRecord record);

  /// Get all health records ordered by timestamp (most recent first)
  /// Returns empty list if no records exist
  Future<List<HealthRecord>> getHealthHistory();

  /// Get health records filtered by type, ordered by timestamp (most recent first)
  /// Returns empty list if no records exist for the specified type
  Future<List<HealthRecord>> getHistoryByType(HealthMetricType type);

  /// Get the count of records for a specific type
  Future<int> getRecordCountByType(HealthMetricType type);

  /// Get the most recent record for a specific type
  /// Returns null if no records exist for the specified type
  Future<HealthRecord?> getMostRecentRecordByType(HealthMetricType type);

  /// Get records within a date range, optionally filtered by type
  Future<List<HealthRecord>> getRecordsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    HealthMetricType? type,
  });

  /// Delete a health record by ID
  /// Throws [RepositoryException] if the delete operation fails
  Future<void> deleteRecord(int id);
}

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception thrown when repository operations fail
class RepositoryException implements Exception {
  final String message;
  final Exception? cause;
  
  const RepositoryException(this.message, [this.cause]);

  @override
  String toString() => 'RepositoryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}