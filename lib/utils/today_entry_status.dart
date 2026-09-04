import 'package:flutter/foundation.dart';

/// Whether today's journal entry exists, kept outside [TodayScreen]'s own
/// state so [MainShell] can show a "logged today" badge on the nav bar's
/// Today tab without querying Supabase a second time — `TodayScreen` is the
/// single source of truth and updates this after every check/save/delete.
final todayEntryLogged = ValueNotifier<bool>(false);
