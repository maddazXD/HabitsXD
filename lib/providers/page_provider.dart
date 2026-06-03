import 'package:flutter/material.dart';
import '../data/page/page.dart';
import '../data/page/page_repository.dart';

class PageProvider extends ChangeNotifier {
  final PageRepository repository;
  List<NotePage> _pages = [];

  PageProvider({required this.repository});

  List<NotePage> get pages => _pages;

  NotePage? getPageById(String id) {
    try {
      return _pages.firstWhere((page) => page.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadPages() async {
    _pages = await repository.fetchPages();
    _sortPages();
    notifyListeners();
  }

  Future<void> addPage(NotePage page) async {
    _pages.add(page);
    _sortPages();
    await _saveAndNotify();
  }

  Future<void> updatePage(NotePage page) async {
    final index = _pages.indexWhere((item) => item.id == page.id);
    if (index == -1) return;
    _pages[index] = page;
    _sortPages();
    await _saveAndNotify();
  }

  Future<void> deletePage(String id) async {
    _pages.removeWhere((page) => page.id == id);
    await _saveAndNotify();
  }

  List<String> getAllTags() {
    final tags = <String>{};
    for (final page in _pages) {
      tags.addAll(page.tags);
    }
    return tags.toList()..sort();
  }

  void _sortPages() {
    _pages.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _saveAndNotify() async {
    notifyListeners();
    await repository.savePages(_pages);
  }
}
