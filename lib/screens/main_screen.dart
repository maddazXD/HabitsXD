import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'habit/habit_list_screen.dart';
import 'home_screen.dart';
import 'focus/focus_screen.dart';
import 'task/task_list_screen.dart';
import 'user_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Helper method to switch tabs
  void _switchTab(int index) {
    if (!mounted) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Map current tab index to its active color so labels match active icon colors
    Color selectedColor;
    switch (_currentIndex) {
      case 0:
        selectedColor = AppTheme.warningAccent;
        break;
      case 1:
        selectedColor = AppTheme.focusColor;
        break;
      case 2:
        selectedColor = AppTheme.taskColor;
        break;
      case 3:
        selectedColor = AppTheme.habitColor;
        break;
      case 4:
      default:
        selectedColor = AppTheme.userColor;
        break;
    }
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onNavigateToFocus: () => _switchTab(1)),
          const FocusScreen(),
          const TaskListScreen(),
          const HabitListScreen(),
          const UserScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: CupertinoTabBar(
            currentIndex: _currentIndex,
            onTap: _switchTab,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
            activeColor: selectedColor,
            inactiveColor:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.75),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.timer),
                label: 'Focus',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.checkmark_square),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.clock),
                label: 'Habits',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
