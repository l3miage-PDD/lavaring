import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../services/auth_service.dart';
import '../widgets/timer_progress_arc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                timerProvider.acknowledgeGoal(); // Reset the flag
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
        // Show the dialog as a side-effect of the state change
        if (timerProvider.goalReached) {
          // Use a post-frame callback to show the dialog after the build is complete
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
                  maxSeconds: 60, // For testing, 1 minute = full circle
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
