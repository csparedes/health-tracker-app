import 'package:equatable/equatable.dart';
import '../models/models.dart';

/// Base class for all health tracking states
abstract class HealthTrackingState extends Equatable {
  const HealthTrackingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class HealthTrackingInitial extends HealthTrackingState {
  const HealthTrackingInitial();
}

/// Loading state
class HealthTrackingLoading extends HealthTrackingState {
  const HealthTrackingLoading();
}

/// State when health records are loaded successfully
class HealthTrackingLoaded extends HealthTrackingState {
  final List<HealthRecord> records;
  final HealthMetricType? currentFilter;

  const HealthTrackingLoaded(
    this.records, {
    this.currentFilter,
  });

  @override
  List<Object?> get props => [records, currentFilter];

  /// Create a copy with updated values
  HealthTrackingLoaded copyWith({
    List<HealthRecord>? records,
    HealthMetricType? currentFilter,
    bool clearFilter = false,
  }) {
    return HealthTrackingLoaded(
      records ?? this.records,
      currentFilter: clearFilter ? null : (currentFilter ?? this.currentFilter),
    );
  }
}

/// State when a health record is successfully added
class HealthRecordAdded extends HealthTrackingState {
  final HealthRecord addedRecord;
  final String successMessage;

  const HealthRecordAdded(
    this.addedRecord, {
    this.successMessage = 'Registro guardado exitosamente',
  });

  @override
  List<Object?> get props => [addedRecord, successMessage];
}

/// State when a health record is successfully deleted
class HealthRecordDeleted extends HealthTrackingState {
  final int deletedRecordId;
  final String successMessage;

  const HealthRecordDeleted(
    this.deletedRecordId, {
    this.successMessage = 'Registro eliminado exitosamente',
  });

  @override
  List<Object?> get props => [deletedRecordId, successMessage];
}

/// State when record count is loaded
class RecordCountLoaded extends HealthTrackingState {
  final HealthMetricType type;
  final int count;

  const RecordCountLoaded(this.type, this.count);

  @override
  List<Object?> get props => [type, count];
}

/// State when most recent record is loaded
class MostRecentRecordLoaded extends HealthTrackingState {
  final HealthMetricType type;
  final HealthRecord? record;

  const MostRecentRecordLoaded(this.type, this.record);

  @override
  List<Object?> get props => [type, record];
}

/// Error state
class HealthTrackingError extends HealthTrackingState {
  final String message;
  final String? details;

  const HealthTrackingError(
    this.message, {
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

/// Validation error state
class HealthTrackingValidationError extends HealthTrackingState {
  final List<String> errors;

  const HealthTrackingValidationError(this.errors);

  @override
  List<Object?> get props => [errors];
}