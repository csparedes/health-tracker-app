import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'health_tracking_event.dart';
import 'health_tracking_state.dart';

/// BLoC for managing health tracking state and business logic
class HealthTrackingBloc extends Bloc<HealthTrackingEvent, HealthTrackingState> {
  final HealthRepository _repository;

  HealthTrackingBloc(this._repository) : super(const HealthTrackingInitial()) {
    on<AddHealthRecord>(_onAddHealthRecord);
    on<LoadHistory>(_onLoadHistory);
    on<FilterByType>(_onFilterByType);
    on<LoadRecordsByDateRange>(_onLoadRecordsByDateRange);
    on<DeleteHealthRecord>(_onDeleteHealthRecord);
    on<GetRecordCountByType>(_onGetRecordCountByType);
    on<GetMostRecentRecordByType>(_onGetMostRecentRecordByType);
  }

  /// Handle adding a new health record
  Future<void> _onAddHealthRecord(
    AddHealthRecord event,
    Emitter<HealthTrackingState> emit,
  ) async {
    emit(const HealthTrackingLoading());

    try {
      // Validate the record using repository validation
      if (_repository is LocalHealthRepository) {
        final localRepo = _repository;
        final validationErrors = localRepo.validateHealthRecord(event.record);
        
        if (validationErrors.isNotEmpty) {
          emit(HealthTrackingValidationError(validationErrors));
          return;
        }
      }

      // Save the record
      await _repository.saveHealthRecord(event.record);

      // Emit success state with confirmation message
      emit(HealthRecordAdded(
        event.record,
        successMessage: _getSuccessMessage(event.record.type),
      ));

      // Automatically reload the history to show updated data
      add(const LoadHistory());
    } on ValidationException catch (e) {
      emit(HealthTrackingValidationError([e.message]));
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al guardar el registro',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al guardar el registro',
        details: e.toString(),
      ));
    }
  }

  /// Handle loading health history
  Future<void> _onLoadHistory(
    LoadHistory event,
    Emitter<HealthTrackingState> emit,
  ) async {
    emit(const HealthTrackingLoading());

    try {
      final records = await _repository.getHealthHistory();
      emit(HealthTrackingLoaded(records));
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al cargar el historial',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al cargar el historial',
        details: e.toString(),
      ));
    }
  }

  /// Handle filtering by type
  Future<void> _onFilterByType(
    FilterByType event,
    Emitter<HealthTrackingState> emit,
  ) async {
    emit(const HealthTrackingLoading());

    try {
      final records = event.type != null
          ? await _repository.getHistoryByType(event.type!)
          : await _repository.getHealthHistory();

      emit(HealthTrackingLoaded(
        records,
        currentFilter: event.type,
      ));
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al filtrar el historial',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al filtrar el historial',
        details: e.toString(),
      ));
    }
  }

  /// Handle loading records by date range
  Future<void> _onLoadRecordsByDateRange(
    LoadRecordsByDateRange event,
    Emitter<HealthTrackingState> emit,
  ) async {
    emit(const HealthTrackingLoading());

    try {
      final records = await _repository.getRecordsByDateRange(
        event.startDate,
        event.endDate,
        type: event.type,
      );

      emit(HealthTrackingLoaded(
        records,
        currentFilter: event.type,
      ));
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al cargar registros por fecha',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al cargar registros por fecha',
        details: e.toString(),
      ));
    }
  }

  /// Handle deleting a health record
  Future<void> _onDeleteHealthRecord(
    DeleteHealthRecord event,
    Emitter<HealthTrackingState> emit,
  ) async {
    emit(const HealthTrackingLoading());

    try {
      await _repository.deleteRecord(event.recordId);

      emit(HealthRecordDeleted(event.recordId));

      // Automatically reload the history to show updated data
      add(const LoadHistory());
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al eliminar el registro',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al eliminar el registro',
        details: e.toString(),
      ));
    }
  }

  /// Handle getting record count by type
  Future<void> _onGetRecordCountByType(
    GetRecordCountByType event,
    Emitter<HealthTrackingState> emit,
  ) async {
    try {
      final count = await _repository.getRecordCountByType(event.type);
      emit(RecordCountLoaded(event.type, count));
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al obtener el conteo de registros',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al obtener el conteo de registros',
        details: e.toString(),
      ));
    }
  }

  /// Handle getting most recent record by type
  Future<void> _onGetMostRecentRecordByType(
    GetMostRecentRecordByType event,
    Emitter<HealthTrackingState> emit,
  ) async {
    try {
      final record = await _repository.getMostRecentRecordByType(event.type);
      emit(MostRecentRecordLoaded(event.type, record));
    } on RepositoryException catch (e) {
      emit(HealthTrackingError(
        'Error al obtener el registro más reciente',
        details: e.message,
      ));
    } catch (e) {
      emit(HealthTrackingError(
        'Error inesperado al obtener el registro más reciente',
        details: e.toString(),
      ));
    }
  }

  /// Get success message based on health metric type
  String _getSuccessMessage(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.glucose => 'Nivel de glucosa guardado exitosamente',
      HealthMetricType.waistDiameter => 'Diámetro de cintura guardado exitosamente',
      HealthMetricType.bodyWeight => 'Peso corporal guardado exitosamente',
    };
  }
}