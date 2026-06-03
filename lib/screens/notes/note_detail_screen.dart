import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/page/page.dart';
import '../../providers/page_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';

class NoteDetailScreen extends StatefulWidget {
  final NotePage? page;

  const NoteDetailScreen({super.key, this.page});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _tagController;
  late List<String> _tags;
  late bool _isFavorite;
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.page?.title ?? '');
    _bodyController = TextEditingController(text: widget.page?.body ?? '');
    _tagController = TextEditingController();
    _tags = List<String>.from(widget.page?.tags ?? []);
    _isFavorite = widget.page?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _savePage() {
    final provider = context.read<PageProvider>();
    final id = widget.page?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final page = NotePage(
      id: id,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      tags: _tags,
      createdAt: widget.page?.createdAt,
      updatedAt: now,
      isFavorite: _isFavorite,
    );

    if (widget.page == null) {
      provider.addPage(page);
    } else {
      provider.updatePage(page);
    }

    Navigator.pop(context);
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isEmpty) return;
    setState(() {
      if (!_tags.contains(tag)) _tags.add(tag);
      _tagController.clear();
    });
  }

  void _useTemplate(String template) {
    setState(() {
      if (_titleController.text.isEmpty) {
        _titleController.text = template;
      }
      _bodyController.text = '${_bodyController.text}\n\n#### ${template}\n- ';
    });
  }

  Future<void> _showAiResultDialog(String title, String result) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(result.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _runAiSummary(SettingsProvider settings) async {
    if (!_validateAi(settings)) return;
    setState(() => _aiLoading = true);
    try {
      final result = await AIService.instance.summarizeText(
        text: _bodyController.text.trim().isEmpty
            ? _titleController.text.trim()
            : _bodyController.text.trim(),
      );
      _bodyController.text = result.trim();
      _showAiResultDialog('AI Summary', result);
    } catch (e) {
      _showAiResultDialog('AI Error', e.toString());
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _runAiGenerateTasks(SettingsProvider settings) async {
    if (!_validateAi(settings)) return;
    setState(() => _aiLoading = true);
    try {
      final result = await AIService.instance.generateTasksFromText(
        text: _bodyController.text.trim().isEmpty
            ? _titleController.text.trim()
            : _bodyController.text.trim(),
      );
      _bodyController.text = '## Tasks\n$result\n\n${_bodyController.text}';
      _showAiResultDialog('AI Task Ideas', result);
    } catch (e) {
      _showAiResultDialog('AI Error', e.toString());
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _runAiSuggestTitle(SettingsProvider settings) async {
    if (!_validateAi(settings)) return;
    setState(() => _aiLoading = true);
    try {
      final result = await AIService.instance.suggestTitle(
        text: _bodyController.text.trim().isEmpty
            ? _titleController.text.trim()
            : _bodyController.text.trim(),
      );
      _titleController.text = result.trim();
      _showAiResultDialog('AI Suggested Title', result);
    } catch (e) {
      _showAiResultDialog('AI Error', e.toString());
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  bool _validateAi(SettingsProvider settings) {
    if (!settings.useAiFeatures) {
      _showAiResultDialog('AI Disabled', 'Please enable AI features in Settings first.');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.page == null;
    final title = widget.page == null ? 'New Note' : 'Edit Note';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _savePage,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Page title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Builder(
                builder: (context) {
                  final settings = context.watch<SettingsProvider>();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.smart_toy),
                              label: const Text('Summarize'),
                              onPressed: _aiLoading
                                  ? null
                                  : () => _runAiSummary(settings),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.list_alt),
                              label: const Text('Generate Tasks'),
                              onPressed: _aiLoading
                                  ? null
                                  : () => _runAiGenerateTasks(settings),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.title),
                              label: const Text('Suggest Title'),
                              onPressed: _aiLoading
                                  ? null
                                  : () => _runAiSuggestTitle(settings),
                            ),
                          ),
                        ],
                      ),
                      if (_aiLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: AppTheme.spaceSmall),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              TextField(
                controller: _bodyController,
                maxLines: 14,
                decoration: const InputDecoration(
                  hintText: 'Start writing your note...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              Text(
                'Tags',
                style: const TextStyle(
                  fontSize: AppTheme.fsBodyLarge,
                  fontWeight: AppTheme.fwBold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Wrap(
                spacing: AppTheme.spaceSmall,
                runSpacing: AppTheme.spaceXSmall,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        hintText: 'Add tag',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  ElevatedButton(
                    onPressed: _addTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXLarge),
              Text(
                'Templates',
                style: const TextStyle(
                  fontSize: AppTheme.fsBodyLarge,
                  fontWeight: AppTheme.fwBold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Wrap(
                spacing: AppTheme.spaceSmall,
                runSpacing: AppTheme.spaceSmall,
                children: [
                  _templateChip('Quick note'),
                  _templateChip('Project plan'),
                  _templateChip('Daily reflection'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _templateChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _useTemplate(label),
    );
  }
}
