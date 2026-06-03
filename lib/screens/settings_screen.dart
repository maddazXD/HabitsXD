import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/focus_provider.dart';
import '../providers/task_provider.dart';
import '../services/backup_service.dart';
import '../widgets/tags.dart';
import '../widgets/categories.dart';
import '../widgets/location_picker_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<String> _appVersionFuture = _loadAppVersion();

  // --- UI HELPERS ---
  Future<String> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'Version ${packageInfo.version}';
  }

  /// Helper untuk buka URL dengan error handling yang benar.
  /// Tidak pakai canLaunchUrl karena di Android 11+ sering return false
  /// kalau <queries> belum didaftarkan di AndroidManifest.xml.
  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak bisa membuka: $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Tampilkan popup QRIS donate agar bisa di-scan langsung
  void _showDonateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Donate via QRIS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan QR di bawah untuk donasi',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/donate.jpg',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAlarmSound(SettingsProvider settings) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final pickedFile = result.files.first;
    if (pickedFile.path == null) return;

    settings.setCustomAlarmSoundPath(pickedFile.path!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Custom alarm song selected: ${pickedFile.name}'),
      ),
    );
  }

  Future<void> _previewAlarmTone(SettingsProvider settings) async {
    final player = AudioPlayer();
    try {
      if (settings.customAlarmSoundPath.isNotEmpty) {
        await player.play(DeviceFileSource(settings.customAlarmSoundPath));
      } else {
        await player.play(AssetSource('ding.mp3'));
      }
      await player.onPlayerComplete.first;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to play alarm tone.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      await player.dispose();
    }
  }

  

  void _showNumberPickerDialog(
    String title,
    int currentValue,
    int min,
    int max,
    Function(int) onSave, {
    String unit = 'minutes',
  }) {
    int tempValue = currentValue;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$tempValue $unit',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Slider(
                  value: tempValue.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: (max - min) ~/ 5,
                  onChanged: (val) =>
                      setDialogState(() => tempValue = val.toInt()),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  onSave(tempValue);
                  Navigator.pop(context);
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.taskColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final focusProvider = context.watch<FocusProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final hiveBoxNames = [
      'focusModesBox',
      'focusSessionsBox',
      'focusTagsBox',
      'habitsBox',
      'tasksBox',
      'userProfileBox',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // --- APPEARANCE ---
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
              ],
              onChanged: (val) {
                if (val != null) settings.setThemeMode(val);
              },
            ),
          ),

          const Divider(height: 32),

          // --- FOCUS & PRODUCTIVITY ---
          _buildSectionHeader('Focus & Productivity'),
          ListTile(
            leading: const Icon(
              Icons.track_changes,
              color: AppTheme.focusColor,
            ),
            title: const Text('Daily Focus Goal'),
            subtitle: Text('${settings.dailyGoalMins} minutes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPickerDialog(
              "Daily Goal",
              settings.dailyGoalMins,
              10,
              480,
              (val) => settings.setDailyGoal(val),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.task_alt, color: AppTheme.taskColor),
            title: const Text('Auto-complete linked task or habit'),
            subtitle: const Text(
              'Marks the selected task or habit as complete when a focus timer finishes.',
            ),
            value: settings.autoCompleteFocusTargetOnFinish,
            onChanged: settings.setAutoCompleteFocusTargetOnFinish,
          ),
          ListTile(
            leading: const Icon(
              Icons.timer_outlined,
              color: AppTheme.warningAccent,
            ),
            title: const Text('Max Stopwatch Limit'),
            subtitle: Text(
              'Prevents accidentally leaving timer on\nCurrently: ${settings.maxStopwatchMins} mins',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPickerDialog(
              "Stopwatch Limit",
              settings.maxStopwatchMins,
              30,
              480,
              (val) => settings.setMaxStopwatch(val),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.linear_scale, color: AppTheme.taskColor),
            title: const Text('Max Phase Node Time'),
            subtitle: Text(
              'Maximum length for a single focus block\nCurrently: ${settings.maxNodeMins} mins',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPickerDialog(
              "Max Node Time",
              settings.maxNodeMins,
              10,
              480,
              (val) => settings.setMaxNode(val),
            ),
          ),

          ListTile(
            leading: const Icon(
              Icons.schedule_outlined,
              color: AppTheme.taskColor,
            ),
            title: const Text('Upcoming Task Window'),
            subtitle: Text('${settings.upcomingTasksDays} days ahead'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showNumberPickerDialog(
              'Upcoming Task Window',
              settings.upcomingTasksDays,
              1,
              60,
              (val) => settings.setUpcomingTasksDays(val),
              unit: 'days',
            ),
          ),

          const Divider(height: 32),

          // --- ORGANIZATION ---
          _buildSectionHeader('Organization'),
          ListTile(
            leading: const Icon(
              Icons.local_offer_outlined,
              color: AppTheme.focusColor,
            ),
            title: const Text('Focus Tags'),
            subtitle: Text('${focusProvider.tags.length} tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const TagsWidget(),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.category_outlined,
              color: AppTheme.taskColor,
            ),
            title: const Text('Task Categories'),
            subtitle: Text('${taskProvider.getAllCategories().length} categories'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showDialog(
              context: context,
              builder: (_) => const CategoriesWidget(),
            ),
          ),

          const Divider(height: 32),

          // --- API & SERVICES ---
          _buildSectionHeader('API & Services'),
          ListTile(
            leading: const Icon(Icons.cloud, color: AppTheme.taskColor),
            title: const Text('Location Search API'),
            subtitle: Text(
              settings.locationApiEndpoint.length > 40
                  ? '${settings.locationApiEndpoint.substring(0, 40)}...'
                  : settings.locationApiEndpoint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.edit),
            onTap: () => showLocationApiDialog(
              context: context,
              isStateMounted: () => mounted,
              settings: settings,
            ),
          ),

          const Divider(height: 32),

          // --- NOTIFICATIONS ---
          _buildSectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.schedule, color: AppTheme.warningAccent),
            title: const Text('Daily Motivation Time'),
            subtitle: Text(settings.notificationTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: settings.notificationTime,
              );
              if (time != null && mounted) {
                settings.setNotificationTime(time);
              }
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.nightlight_round,
              color: AppTheme.habitColor,
            ),
            title: const Text('End of Day Checkup Time'),
            subtitle: Text(settings.endOfDayTime.format(context)),
            trailing: const Icon(Icons.edit),
            onTap: () async {
              final TimeOfDay? time = await showTimePicker(
                context: context,
                initialTime: settings.endOfDayTime,
              );
              if (time != null && mounted) {
                settings.setEndOfDayTime(time);
              }
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.alarm, color: AppTheme.warningAccent),
            title: const Text('Use alarm sound'),
            subtitle: const Text(
              'Play a louder sound for reminders and timer end events.',
            ),
            value: settings.useAlarmSound,
            onChanged: settings.setUseAlarmSound,
          ),
          ListTile(
            leading: const Icon(Icons.music_note, color: AppTheme.focusColor),
            title: const Text('Alarm Sound'),
            subtitle: Text(settings.customAlarmSoundPath.isNotEmpty
                ? settings.customAlarmSoundPath.split('/').last
                : 'Default tone'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.customAlarmSoundPath.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _previewAlarmTone(settings),
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _pickAlarmSound(settings),
          ),
          if (settings.customAlarmSoundPath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextButton(
                onPressed: () {
                  settings.clearCustomAlarmSoundPath();
                },
                child: const Text('Reset to default sound'),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.smart_toy, color: AppTheme.taskColor),
            title: const Text('Enable AI features'),
            subtitle: const Text(
              'Use AI to summarize notes and generate task ideas.',
            ),
            value: settings.useAiFeatures,
            onChanged: settings.setUseAiFeatures,
          ),

          const Divider(height: 32),

          // --- DATA & BACKUP ---
          _buildSectionHeader('Data & Backup'),
          ListTile(
            leading: const Icon(
              Icons.cloud_upload_outlined,
              color: AppTheme.taskColor,
            ),
            title: const Text('Export Backup'),
            subtitle: const Text(
              'Save your data locally or share it to the cloud',
            ),
            onTap: () =>
                BackupService.exportBackup(context, boxNames: hiveBoxNames),
          ),
          ListTile(
            leading: const Icon(Icons.restore, color: AppTheme.focusColor),
            title: const Text('Restore Backup'),
            subtitle: const Text(
              'Overwrite current data from a backup zip file',
            ),
            onTap: () =>
                BackupService.importBackup(context, boxNames: hiveBoxNames),
          ),

          const Divider(height: 32),

          // --- SUPPORT & FEEDBACK ---
          _buildSectionHeader('Support & Feedback'),
          ListTile(
            leading: const Icon(
              Icons.forum_outlined,
              color: AppTheme.focusColor,
            ),
            title: const Text('Community & Help'),
            subtitle: const Text('Join our WhatsApp group'),
            trailing: const Icon(
              Icons.open_in_new,
              size: 16,
              color: Colors.grey,
            ),
            onTap: () => _launchURL('https://chat.whatsapp.com/KbMxJMUWOii3tBiZgyY4YT'),
          ),
          ListTile(
            leading: const Icon(
              Icons.bug_report_outlined,
              color: AppTheme.habitColor,
            ),
            title: const Text('Send Feedback'),
            subtitle: const Text('Chat with us on WhatsApp'),
            trailing: const Icon(
              Icons.open_in_new,
              size: 16,
              color: Colors.grey,
            ),
            onTap: () => _launchURL('https://chat.whatsapp.com/KbMxJMUWOii3tBiZgyY4YT'),
          ),

          const Divider(height: 32),

          // --- ABOUT & INFO SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Card(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 24.0, bottom: 8.0),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      foregroundImage: AssetImage('assets/logo.png'),
                    ),
                  ),
                  const Text(
                    "HabitsXD",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  FutureBuilder<String>(
                    future: _appVersionFuture,
                    builder: (context, snapshot) {
                      final versionText = snapshot.data ?? 'Version';
                      return Text(
                        versionText,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  const ListTile(
                    leading: Icon(Icons.person, color: Colors.deepOrange),
                    title: Text('Built by MaddazXD'),
                    subtitle: Text('Solo Developer & Maintainer'),
                  ),
                  ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/donate.jpg',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: const Text('Donate'),
                    subtitle: const Text('Scan QRIS untuk donasi'),
                    trailing: const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () => _showDonateDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.code, color: Colors.blue),
                    title: const Text('Source Code'),
                    subtitle: const Text('GitHub Repository'),
                    trailing: const Icon(
                      Icons.open_in_new,
                      size: 16,
                      color: Colors.grey,
                    ),
                    // FIXED: pakai _launchURL, tidak pakai canLaunchUrl
                    onTap: () => _launchURL('https://github.com/maddazXD/HabitsXD'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
