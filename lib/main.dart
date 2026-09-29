import 'package:flutter/material.dart';

import 'game_state.dart';
import 'screens/computers_screen.dart';
import 'screens/home_screen.dart';
import 'screens/network_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/research_screen.dart';
import 'services/audio_service.dart';
import 'theme/app_theme.dart';
import 'widgets/offline_reward_dialog.dart';
import 'widgets/tutorial_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameState.load();
  runApp(const ByteTycoonApp());
}

class ByteTycoonApp extends StatefulWidget {
  const ByteTycoonApp({super.key});

  @override
  State<ByteTycoonApp> createState() => _ByteTycoonAppState();
}

class _ByteTycoonAppState extends State<ByteTycoonApp> with WidgetsBindingObserver {
  final GameState gs = GameState.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    gs.startGameLoop();
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    gs.stopGameLoop();
    super.dispose();
  }

  Future<void> _onStart() async {
    // offline income popup (first launch = no offline time)
    final report = gs.resume();
    if (!mounted) return;
    if (gs.saveDataError) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('SAVE DATA ERROR - restored from backup save.'),
        duration: Duration(seconds: 4),
      ));
    }
    if (report != null && report.coins > 0) {
      await OfflineRewardDialog.show(context, report.seconds, report.coins);
    }
    if (!mounted) return;
    if (!gs.tutorialSeen) {
      await TutorialOverlay.show(context);
      gs.markTutorialSeen();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Truly backgrounded: save, then stop the tick loop so no income
      // accrues twice (once live in background, once as offline catch-up
      // on resume).
      gs.pauseAndSave();
      gs.stopGameLoop();
    } else if (state == AppLifecycleState.inactive) {
      // Transient (e.g. a system dialog, app-switcher preview): still not
      // visible/interactive, so save defensively, but don't stop the loop
      // since we may come straight back without a real "away" gap.
      gs.pauseAndSave();
    } else if (state == AppLifecycleState.resumed) {
      gs.startGameLoop();
      final report = gs.resume();
      if (report != null && report.coins > 0 && mounted) {
        OfflineRewardDialog.show(context, report.seconds, report.coins);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BYTE TYCOON',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final GameState gs = GameState.instance;

  void _drainAchievements(BuildContext context) {
    if (gs.achievementQueue.isEmpty) return;
    final names = gs.achievementQueue.toList();
    gs.achievementQueue.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final n in names) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ACHIEVEMENT UNLOCKED: $n'),
          duration: const Duration(seconds: 2),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Build only the active tab (keyed, so its scroll/state is preserved
    // across tab switches) instead of an IndexedStack that keeps all 5 tabs
    // mounted and rebuilding on every 250ms game tick.
    final pages = [
      HomeScreen(key: const PageStorageKey('home'), onGoToComputers: () => setState(() => _index = 1)),
      const ComputersScreen(key: PageStorageKey('computers')),
      const NetworkScreen(key: PageStorageKey('network')),
      const ResearchScreen(key: PageStorageKey('research')),
      const ProfileScreen(key: PageStorageKey('profile')),
    ];
    return Scaffold(
      body: AnimatedBuilder(
        animation: gs,
        builder: (context, _) {
          _drainAchievements(context);
          return pages[_index];
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          AudioService.click();
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.computer_outlined), selectedIcon: Icon(Icons.computer), label: 'Computers'),
          NavigationDestination(icon: Icon(Icons.hub_outlined), selectedIcon: Icon(Icons.hub), label: 'Network'),
          NavigationDestination(icon: Icon(Icons.science_outlined), selectedIcon: Icon(Icons.science), label: 'Research'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
