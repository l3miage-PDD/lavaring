import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart'; // Import the service
import '../widgets/timer_progress_arc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // Request notification permissions when the screen is first built.
    Provider.of<NotificationService>(context, listen: false).requestPermissions();
  }

  void _showGoalDialog(BuildContext context) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bravo !'),
          content: const Text('Vous avez atteint votre objectif de 1 minute.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                timerProvider.acknowledgeGoal();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        if (timerProvider.goalReached) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showGoalDialog(context);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Thermal Ring Tracker'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authService.signOut(),
              )
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimerProgressArc(
                  totalSeconds: timerProvider.totalSeconds,
                  maxSeconds: 60,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!timerProvider.isRunning)
                      ElevatedButton(
                        onPressed: () => timerProvider.startTimer(),
                        child: const Text('Démarrer'),
                      ),
                    if (timerProvider.isRunning)
                      ElevatedButton(
                        onPressed: () => timerProvider.pauseTimer(),
                        child: const Text('Pause'),
                      ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () => timerProvider.resetTimer(),
                      child: const Text('Réinitialiser'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
