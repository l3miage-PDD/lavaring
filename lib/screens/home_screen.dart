
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../services/auth_service.dart';
import '../widgets/timer_progress_arc.dart';
import '../services/background_service.dart'; // Import for goalInSeconds

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {

        return Scaffold(
          appBar: AppBar(
            title: const Text('Lava Ring'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => authService.signOut(),
                tooltip: 'Déconnexion',
              )
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TimerProgressArc(
                  totalSeconds: timerProvider.totalSeconds,
                  // Use the constant from the background service for consistency
                  maxSeconds: goalInSeconds, 
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!timerProvider.isRunning)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => timerProvider.startTimer(),
                        label: const Text('Démarrer'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                      ),
                    if (timerProvider.isRunning)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.pause),
                        onPressed: () => timerProvider.pauseTimer(),
                        label: const Text('Pause'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
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
