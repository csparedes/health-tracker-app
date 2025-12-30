import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/blocs.dart';
import 'database/database.dart';
import 'repositories/repositories.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final database = SQLiteHealthDatabase();
  await database.initialize();
  
  // Create repository
  final repository = LocalHealthRepository(database);
  
  runApp(HealthTrackerApp(repository: repository));
}

class HealthTrackerApp extends StatelessWidget {
  final HealthRepository repository;
  
  const HealthTrackerApp({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HealthTrackingBloc(repository),
      child: MaterialApp(
        title: 'Health Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HealthTrackerHome(),
      ),
    );
  }
}

class HealthTrackerHome extends StatelessWidget {
  const HealthTrackerHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tracker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome section
            Card(
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
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions section
            Text(
              'Acciones Rápidas',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Add new record button
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.teal,
                    size: 32,
                  ),
                ),
                title: const Text(
                  'Registrar Nuevos Datos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Agrega mediciones de glucosa, cintura o peso'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HealthDataEntryScreen(),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 12),
            
            // View history button
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                title: const Text(
                  'Ver Historial',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Consulta tus registros anteriores'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const HealthHistoryScreen(),
                    ),
                  );
                },
              ),
            ),
            
            const Spacer(),
            
            // Info section
            Container(
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
            ),
          ],
        ),
      ),
    );
  }
}
