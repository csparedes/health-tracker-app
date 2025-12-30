import 'package:equatable/equatable.dart';
import '../models/models.dart';

/// Base class for all health tracking events
abstract class HealthTrackingEvent extends Equatable {
  const HealthTrackingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to add a new health record
class AddHealthRecord extends HealthTrackingEvent {
  final HealthRecord record;

  const AddHealthRecord(this.record);

  @override
  List<Object?> get props => [record];
}

/// Event to load health history
class LoadHistory extends HealthTrackingEvent {
  const LoadHistory();
}

/// Event to filter history by type
class FilterByType extends HealthTrackingEvent {
  final HealthMetricType? type;

  const FilterByType(this.type);

  @override
  List<Object?> get props => [type];
}

/// Event to load records by date range
class LoadRecordsByDateRange extends HealthTrackingEvent {
  final DateTime startDate;
  final DateTime endDate;
  final HealthMetricType? type;

  const LoadRecordsByDateRange(
    this.startDate,
    this.endDate, {
    this.type,
  });

  @override
  List<Object?> get props => [startDate, endDate, type];
}

/// Event to delete a health record
class DeleteHealthRecord extends HealthTrackingEvent {
  final int recordId;

  const DeleteHealthRecord(this.recordId);

  @override
  List<Object?> get props => [recordId];
}

/// Event to get record count by type
class GetRecordCountByType extends HealthTrackingEvent {
  final HealthMetricType type;

  const GetRecordCountByType(this.type);

  @override
  List<Object?> get props => [type];
}

/// Event to get most recent record by type
class GetMostRecentRecordByType extends HealthTrackingEvent {
  final HealthMetricType type;

  const GetMostRecentRecordByType(this.type);

  @override
  List<Object?> get props => [type];
}