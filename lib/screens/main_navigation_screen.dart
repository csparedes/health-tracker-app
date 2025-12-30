import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/blocs.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'health_data_entry_screen.dart';
import 'health_history_screen.dart';

/// Main navigation screen with bottom tabs and quick entry options
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  HealthMetricType? _selectedEntryType;

  List<Widget> get _screens => [
    const HomeScreen(),
    HealthDataEntryScreen(initialType: _selectedEntryType),
    const HealthHistoryScreen(),
  ];

  /// Navigate to data entry tab with specific metric type
  void navigateToDataEntryWithType(HealthMetricType type) {
    setState(() {
      _selectedEntryType = type;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Clear selected entry type when manually navigating to entry tab
            if (index == 1) {
              _selectedEntryType = null;
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Registrar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}

/// Home screen with quick entry options and recent measurements summary
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load recent data when home screen initializes
    _loadRecentData();
  }

  void _loadRecentData() {
    final bloc = context.read<HealthTrackingBloc>();
    // Load recent records for each type
    for (final type in HealthMetricType.values) {
      bloc.add(GetMostRecentRecordByType(type));
      bloc.add(GetRecordCountByType(type));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
            onPressed: _loadRecentData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadRecentData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome section
              _buildWelcomeCard(),
              
              const SizedBox(height: 24),
              
              // Quick entry section
              _buildQuickEntrySection(),
              
              const SizedBox(height: 24),
              
              // Recent measurements summary
              _buildRecentMeasurementsSection(),
              
              const SizedBox(height: 24),
              
              // Info section
              _buildInfoSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build welcome card
  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.health_and_safety,
              size: 64,
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            Text(
              'Bienvenido a Health Tracker',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra y monitorea tus datos de salud de manera fácil y segura',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick entry section
  Widget _buildQuickEntrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registro Rápido',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Quick entry buttons for each metric type
        ...HealthMetricType.values.map((type) => _buildQuickEntryCard(type)),
      ],
    );
  }

  /// Build quick entry card for a specific metric type
  Widget _buildQuickEntryCard(HealthMetricType type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColorForType(type).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getIconForType(type),
            color: _getColorForType(type),
            size: 28,
          ),
        ),
        title: Text(
          type.displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Registrar nuevo valor en ${type.unit}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          _navigateToDataEntry(type);
        },
      ),
    );
  }

  /// Build recent measurements summary section
  Widget _buildRecentMeasurementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Resumen Reciente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to history tab
                if (context.findAncestorStateOfType<_MainNavigationScreenState>() != null) {
                  context.findAncestorStateOfType<_MainNavigationScreenState>()!.setState(() {
                    context.findAncestorStateOfType<_MainNavigationScreenState>()!._currentIndex = 2;
                  });
                }
              },
              child: const Text('Ver todo'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Recent measurements cards
        ...HealthMetricType.values.map((type) => _buildRecentMeasurementCard(type)),
      ],
    );
  }

  /// Build recent measurement card for a specific metric type
  Widget _buildRecentMeasurementCard(HealthMetricType type) {
    return BlocBuilder<HealthTrackingBloc, HealthTrackingState>(
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getColorForType(type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getIconForType(type),
                    color: _getColorForType(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildRecentValueDisplay(type, state),
                    ],
                  ),
                ),
                _buildRecordCountDisplay(type, state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build recent value display
  Widget _buildRecentValueDisplay(HealthMetricType type, HealthTrackingState state) {
    if (state is MostRecentRecordLoaded && state.type == type) {
      if (state.record != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.record!.formattedValue,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            Text(
              state.record!.formattedTimestamp,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        );
      } else {
        return Text(
          'Sin registros',
          style: TextStyle(
            color: Colors.grey[500],
            fontStyle: FontStyle.italic,
          ),
        );
      }
    }
    
    return Text(
      'Cargando...',
      style: TextStyle(
        color: Colors.grey[500],
        fontSize: 12,
      ),
    );
  }

  /// Build record count display
  Widget _buildRecordCountDisplay(HealthMetricType type, HealthTrackingState state) {
    if (state is RecordCountLoaded && state.type == type) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${state.count}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        '-',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Build info section
  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Todos tus datos se almacenan localmente en tu dispositivo para garantizar tu privacidad.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to data entry with pre-selected type
  void _navigateToDataEntry(HealthMetricType type) {
    // Set the selected type and navigate to data entry tab
    final mainState = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (mainState != null) {
      mainState.navigateToDataEntryWithType(type);
    }
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