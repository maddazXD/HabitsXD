import 'page.dart';

abstract class PageRepository {
  Future<List<NotePage>> fetchPages();
  Future<void> savePages(List<NotePage> pages);
}
