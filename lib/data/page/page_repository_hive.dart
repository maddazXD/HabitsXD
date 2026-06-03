import 'package:hive/hive.dart';
import 'page.dart';
import 'page_repository.dart';

class HivePageRepository implements PageRepository {
  static const String boxName = 'pagesBox';

  @override
  Future<List<NotePage>> fetchPages() async {
    final box = await Hive.openBox<NotePage>(boxName);
    return box.values.toList();
  }

  @override
  Future<void> savePages(List<NotePage> pages) async {
    final box = await Hive.openBox<NotePage>(boxName);
    final Map<String, NotePage> pageMap = {for (var page in pages) page.id: page};

    final keysToDelete = box.keys.where((key) => !pageMap.containsKey(key)).toList();
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    await box.putAll(pageMap);
  }
}
