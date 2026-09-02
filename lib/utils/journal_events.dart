import 'package:flutter/foundation.dart';

/// Fires whenever a journal entry is created, updated, or deleted anywhere
/// in the app. All three main-shell tabs stay mounted at once
/// (`IndexedStack`), each holding its own snapshot fetched once — this lets
/// a tab refresh its snapshot when the same data changes from a different
/// tab (e.g. today's entry gets deleted from History while the Today tab
/// still shows its old text).
class JournalEventBus extends ChangeNotifier {
  void notifyChanged() => notifyListeners();
}

final journalEntriesChanged = JournalEventBus();
