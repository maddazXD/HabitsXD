import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/page_provider.dart';
import '../../data/page/page.dart';
import '../../theme/app_theme.dart';
import 'note_detail_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  String _searchQuery = '';
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final pageProvider = context.watch<PageProvider>();
    final pages = pageProvider.pages.where((page) {
      final query = _searchQuery.toLowerCase();
      final titleMatches = page.title.toLowerCase().contains(query);
      final bodyMatches = page.body.toLowerCase().contains(query);
      final tagMatches = page.tags.any((tag) => tag.toLowerCase().contains(query));
      final tagFilter = _selectedTag == null || page.tags.contains(_selectedTag);
      return tagFilter && (titleMatches || bodyMatches || tagMatches);
    }).toList();

    final allTags = pageProvider.getAllTags();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_grid_2x2),
            tooltip: 'New Note',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NoteDetailScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLarge,
                AppTheme.spaceLarge,
                AppTheme.spaceLarge,
                AppTheme.spaceSmall,
              ),
              child: CupertinoSearchTextField(
                placeholder: 'Search notes, tags, or text...',
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            if (allTags.isNotEmpty)
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge),
                  itemCount: allTags.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spaceSmall),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedTag == null,
                          onSelected: (_) => setState(() => _selectedTag = null),
                        ),
                      );
                    }
                    final tag = allTags[index - 1];
                    return Padding(
                      padding: const EdgeInsets.only(right: AppTheme.spaceSmall),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: _selectedTag == tag,
                        onSelected: (_) => setState(
                          () => _selectedTag = _selectedTag == tag ? null : tag,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Expanded(
              child: pages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet. Tap + to create a page.'
                              : 'No notes match your search.',
                          style: TextStyle(
                            fontSize: AppTheme.fsBodyLarge,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.65),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(AppTheme.spaceLarge),
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final page = pages[index];
                        return _buildNoteCard(context, page);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_add_button',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteDetailScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NotePage page) {
    final preview = page.body.isEmpty ? 'No content yet' : page.body.trim().split('\n').first;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceMedium),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteDetailScreen(page: page)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                page.title.isEmpty ? 'Untitled page' : page.title,
                style: const TextStyle(
                  fontSize: AppTheme.fsHeadingSmall,
                  fontWeight: AppTheme.fwExtraBold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (page.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceSmall),
                Wrap(
                  spacing: AppTheme.spaceSmall,
                  runSpacing: AppTheme.spaceXSmall,
                  children: page.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceVariant,
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
