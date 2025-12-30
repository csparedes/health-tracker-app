import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../models/models.dart';

/// Screen for displaying health data history
class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  HealthMetricType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Load history when screen initializes
    context.read<HealthTrackingBloc>().add(const LoadHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Salud'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Filter button
          PopupMenuButton<HealthMetricType?>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filtrar por tipo',
            onSelected: (HealthMetricType? type) {
              setState(() {
                _selectedFilter = type;
              });
              context.read<HealthTrackingBloc>().add(FilterByType(type));
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<HealthMetricType?>(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Todos los registros'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              ...HealthMetricType.values.map((type) => PopupMenuItem<HealthMetricType>(
                value: type,
                child: Row(
                  children: [
                    Icon(_getIconForType(type)),
                    const SizedBox(width: 8),
                    Text(type.displayName),
                  ],
                ),
              )),
            ],
          ),
        ],
      ),
      body: BlocBuilder<HealthTrackingBloc, HealthTrackingState>(
        builder: (context, state) {
          if (state is HealthTrackingLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando historial...'),
                ],
              ),
            );
          } else if (state is HealthTrackingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar el historial',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<HealthTrackingBloc>().add(const LoadHistory());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          } else if (state is HealthTrackingLoaded) {
            final records = state.records;
            
            if (records.isEmpty) {
              return _buildEmptyState();
            }

            return _buildHistoryList(records);
          }

          // Initial state or other states
          return _buildEmptyState();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pop(); // Go back to main screen to add new record
        },
        tooltip: 'Agregar nuevo registro',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build the empty state when no records exist
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              _selectedFilter != null 
                  ? 'No hay registros de ${_selectedFilter!.displayName.toLowerCase()}'
                  : 'No hay registros de salud',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter != null
                  ? 'Cambia el filtro o agrega un nuevo registro de ${_selectedFilter!.displayName.toLowerCase()}'
                  : 'Comienza registrando tus primeras mediciones de salud',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to add new record
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Agregar Primer Registro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            if (_selectedFilter != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedFilter = null;
                  });
                  context.read<HealthTrackingBloc>().add(const FilterByType(null));
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Ver todos los registros'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the history list with records
  Widget _buildHistoryList(List<HealthRecord> records) {
    // Group records by date for better organization
    final groupedRecords = _groupRecordsByDate(records);
    
    return RefreshIndicator(
      onRefresh: () async {
        context.read<HealthTrackingBloc>().add(
          _selectedFilter != null 
              ? FilterByType(_selectedFilter)
              : const LoadHistory()
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: groupedRecords.length,
        itemBuilder: (context, index) {
          final dateGroup = groupedRecords[index];
          return _buildDateGroup(dateGroup);
        },
      ),
    );
  }

  /// Build a date group with its records
  Widget _buildDateGroup(DateGroup dateGroup) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            dateGroup.dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        
        // Records for this date
        ...dateGroup.records.map((record) => _buildRecordCard(record)),
        
        const SizedBox(height: 16),
      ],
    );
  }

  /// Build a card for a single health record
  Widget _buildRecordCard(HealthRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColorForType(record.type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(record.type),
            color: _getColorForType(record.type),
            size: 24,
          ),
        ),
        title: Text(
          record.type.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              record.formattedValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTime(record.timestamp),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.notes!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Text(
          _formatTime(record.timestamp),
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
          ),
        ),
        onTap: () {
          _showRecordDetails(record);
        },
      ),
    );
  }

  /// Show detailed view of a record
  void _showRecordDetails(HealthRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getIconForType(record.type),
                color: _getColorForType(record.type),
              ),
              const SizedBox(width: 8),
              Text(record.type.displayName),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Valor', record.formattedValue),
              _buildDetailRow('Fecha', record.formattedTimestamp),
              if (record.notes != null && record.notes!.isNotEmpty)
                _buildDetailRow('Notas', record.notes!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// Build a detail row for the record details dialog
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /// Group records by date
  List<DateGroup> _groupRecordsByDate(List<HealthRecord> records) {
    final Map<String, List<HealthRecord>> grouped = {};
    
    for (final record in records) {
      final dateKey = _getDateKey(record.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add(record);
    }
    
    return grouped.entries.map((entry) {
      return DateGroup(
        dateKey: entry.key,
        dateLabel: _getDateLabel(entry.key),
        records: entry.value,
      );
    }).toList();
  }

  /// Get date key for grouping (YYYY-MM-DD)
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get formatted date label
  String _getDateLabel(String dateKey) {
    final parts = dateKey.split('-');
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date == today) {
      return 'Hoy';
    } else if (date == yesterday) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get icon for metric type
  IconData _getIconForType(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.glucose => Icons.bloodtype,
      HealthMetricType.waistDiameter => Icons.straighten,
      HealthMetricType.bodyWeight => Icons.monitor_weight,
    };
  }

  /// Get color for metric type
  Color _getColorForType(HealthMetricType type) {
    return switch (type) {
      HealthMetricType.glucose => Colors.red,
      HealthMetricType.waistDiameter => Colors.orange,
      HealthMetricType.bodyWeight => Colors.blue,
    };
  }
}

/// Class to group records by date
class DateGroup {
  final String dateKey;
  final String dateLabel;
  final List<HealthRecord> records;

  DateGroup({
    required this.dateKey,
    required this.dateLabel,
    required this.records,
  });
}