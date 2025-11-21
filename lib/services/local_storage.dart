// Temporary in-memory storage (replace with shared_preferences later)
class LocalStorageService {
  static final List<String> _itemSuggestions = [];

  static Future<void> addItemSuggestion(String item) async {
    if (!_itemSuggestions.contains(item)) {
      _itemSuggestions.add(item);
    }
  }

  static Future<List<String>> getItemSuggestions() async {
    return _itemSuggestions;
  }

  static Future<void> removeItemSuggestion(String item) async {
    _itemSuggestions.remove(item);
  }
}
