import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timety/providers/user_provider.dart';
import 'package:timety/screens/settings_screen.dart';
import 'package:timety/utils/greeting_utils.dart';
import '../data/habit/habit_models.dart';
import '../providers/habit_provider.dart';
import '../data/task/task.dart';
import '../providers/task_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/page_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/habit_utils.dart';
import '../widgets/list_tiles/task_list_tile.dart';
import 'notes/notes_list_screen.dart';
import 'task/task_detail_screen.dart';
import 'task/task_list_screen.dart';
import 'habit/habit_detail_screen.dart';
import 'habit/habit_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNavigateToFocus;

  const HomeScreen({super.key, required this.onNavigateToFocus});

  @override
  Widget build(BuildContext context) {
    final userName = context.watch<UserProvider>().name;
    final focusProvider = context.watch<FocusProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final habitProvider = context.watch<HabitProvider>();
    final pageProvider = context.watch<PageProvider>();
    final settings = context.watch<SettingsProvider>();

    final int focusMinsToday = focusProvider.getMinutesFocusedToday();
    final int dailyTarget = settings.dailyGoalMins;
    final double focusProgress = (focusMinsToday / dailyTarget).clamp(0.0, 1.0);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final List<Habit> todaysHabits = habitProvider.getHabitsForDay(today).where(
      (habit) {
        final completionsThisWeek = habitProvider.getCompletionsThisWeek(
          habit,
          includeToday: false,
        );
        final targetDays = habit.targetDaysPerWeek;

        return targetDays == null || completionsThisWeek < targetDays;
      },
    ).toList();

    // Urgent Tasks
    final List<Task> urgentTasks = taskProvider.tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return dueDay.isBefore(today) || dueDay.isAtSameMomentAs(today);
    }).toList();
    urgentTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    final upcomingWindowDays = settings.upcomingTasksDays;
    final upcomingEndDate = todayDate.add(Duration(days: upcomingWindowDays));
    final recentNotes = pageProvider.pages.take(2).toList();
    final List<Task> upcomingTasks = taskProvider.tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;

      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );

      return dueDay.isAfter(todayDate) &&
          (dueDay.isBefore(upcomingEndDate) ||
              dueDay.isAtSameMomentAs(upcomingEndDate));
    }).toList();
    upcomingTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    Widget _summaryCard(
      Color accent,
      String label,
      String value,
      String caption,
    ) {
      return Expanded(
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.circle,
                        size: 18,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMedium),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: AppTheme.fwBold,
                        fontSize: AppTheme.fsBodyMedium,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceLarge),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: AppTheme.fsHeadingLarge,
                    fontWeight: AppTheme.fwExtraBold,
                    color: accent,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: AppTheme.fsBodySmall,
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _sectionCard(String title, Widget child, {VoidCallback? onViewAll}) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTheme.fsBodyLarge,
                      fontWeight: AppTheme.fwBold,
                    ),
                  ),
                  const Spacer(),
                  if (onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text('View All'),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              child,
            ],
          ),
        ),
      );
    }

    Widget _taskPreview(Task task) {
      return InkWell(
        borderRadius: AppTheme.brLarge,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          decoration: BoxDecoration(
            borderRadius: AppTheme.brLarge,
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontWeight: AppTheme.fwBold,
                  fontSize: AppTheme.fsBodyLarge,
                ),
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.75),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceSmall),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    task.dueDate != null
                        ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                        : 'No due date',
                    style: const TextStyle(fontSize: AppTheme.fsBodySmall),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget _habitPreview(Habit habit) {
      final isDone = habitProvider.isCompletedOn(habit, today);
      return InkWell(
        borderRadius: AppTheme.brLarge,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HabitDetailScreen(habit: habit, isEditing: true),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          decoration: BoxDecoration(
            borderRadius: AppTheme.brLarge,
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: const TextStyle(
                        fontWeight: AppTheme.fwBold,
                        fontSize: AppTheme.fsBodyLarge,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceSmall),
                    Text(
                      HabitUtils.buildHabitSubtitle(habit, habitProvider),
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              Checkbox(
                value: isDone,
                onChanged: (_) => habitProvider.toggleCompletionToday(
                  habit,
                  userProvider: context.read<UserProvider>(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitsXD'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GreetingUtils.getGreeting(userName),
                style: const TextStyle(
                  fontSize: AppTheme.fsHeadingLarge,
                  fontWeight: AppTheme.fwExtraBold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                GreetingUtils.getDailyMotivationText(),
                style: const TextStyle(
                  fontSize: AppTheme.fsBodyLarge,
                  fontWeight: AppTheme.fwBold,
                  color: AppTheme.taskColor,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryCard(
                    AppTheme.focusColor,
                    'Focus',
                    '${(focusProgress * 100).toInt()}%',
                    '$focusMinsToday / $dailyTarget mins today',
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  _summaryCard(
                    AppTheme.warningColor,
                    'Tasks',
                    '${urgentTasks.length} due',
                    'Urgent tasks ready for review',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              _summaryCard(
                AppTheme.typeHabitColor,
                'Habits',
                '${todaysHabits.length} today',
                'Your daily habit rhythm',
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              _sectionCard(
                'Recent Notes',
                recentNotes.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppTheme.spaceLarge,
                          horizontal: AppTheme.spaceSmall,
                        ),
                        child: Text(
                          'Create a note to capture ideas, pages, and templates.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                        ),
                      )
                    : Column(
                        children: recentNotes
                            .map(
                              (note) => InkWell(
                                borderRadius: AppTheme.brLarge,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => NoteDetailScreen(page: note),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(
                                    bottom: AppTheme.spaceSmall,
                                  ),
                                  padding: const EdgeInsets.all(AppTheme.spaceMedium),
                                  decoration: BoxDecoration(
                                    borderRadius: AppTheme.brLarge,
                                    color:
                                        Theme.of(context).colorScheme.surfaceVariant,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        note.title.isEmpty
                                            ? 'Untitled note'
                                            : note.title,
                                        style: const TextStyle(
                                          fontWeight: AppTheme.fwBold,
                                          fontSize: AppTheme.fsBodyLarge,
                                        ),
                                      ),
                                      const SizedBox(height: AppTheme.spaceXSmall),
                                      Text(
                                        note.body.isEmpty
                                            ? 'No content yet.'
                                            : note.body.split('\n').first,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesListScreen()),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              if (urgentTasks.isNotEmpty)
                _sectionCard(
                  'Urgent Tasks',
                  Column(
                    children: urgentTasks
                        .take(3)
                        .map((task) => _taskPreview(task))
                        .toList(),
                  ),
                  onViewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TaskListScreen(),
                    ),
                  ),
                ),
              if (todaysHabits.isNotEmpty)
                _sectionCard(
                  'Habits Today',
                  Column(
                    children: todaysHabits
                        .take(4)
                        .map((habit) => _habitPreview(habit))
                        .toList(),
                  ),
                  onViewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HabitListScreen(),
                    ),
                  ),
                ),
              if (urgentTasks.isEmpty && todaysHabits.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLarge),
                    child: Center(
                      child: Text(
                        "You're all caught up for today!",
                        style: TextStyle(
                          fontSize: AppTheme.fsBodyLarge,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppTheme.spaceLarge),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TaskDetailScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
