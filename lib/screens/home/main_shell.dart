import 'package:flutter/material.dart';

import '../../utils/today_entry_status.dart';
import '../account/account_screen.dart';
import '../history/history_screen.dart';
import '../today/today_screen.dart';

/// Main navigation shell shown once a user is signed in: Today / History /
/// Account, each a self-contained tab kept alive in an [IndexedStack] so
/// switching tabs doesn't lose in-progress state (e.g. a draft journal entry).
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  // Not `const`/`static` because Today needs a callback into this state (its
  // hero card's "View history" action jumps straight to the History tab).
  late final _tabs = [
    TodayScreen(onViewHistory: () => setState(() => _selectedIndex = 1)),
    const HistoryScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: _FloatingNavBar(
          selectedIndex: _selectedIndex,
          onSelect: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}

/// A pill-shaped nav bar with History and Account as plain icon buttons and
/// Today as a raised circular button poking above the bar — Today doubles
/// as both a destination and the app's primary daily action (log how you're
/// feeling), so it gets the same visual emphasis a habit-tracker app gives
/// its main action button.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _barHeight = 68.0;
  static const _raisedButtonSize = 58.0;
  static const _totalHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: _totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: _barHeight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.14),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SideNavButton(
                    icon: Icons.history_outlined,
                    selectedIcon: Icons.history,
                    label: 'History',
                    selected: selectedIndex == 1,
                    onTap: () => onSelect(1),
                  ),
                  const SizedBox(width: _raisedButtonSize),
                  _SideNavButton(
                    icon: Icons.account_circle_outlined,
                    selectedIcon: Icons.account_circle,
                    label: 'Account',
                    selected: selectedIndex == 2,
                    onTap: () => onSelect(2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _RaisedTodayButton(
                selected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _RaisedTodayButton extends StatelessWidget {
  const _RaisedTodayButton({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Today',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.secondary,
                border: Border.all(color: scheme.surfaceContainerLow, width: 6),
                boxShadow: [
                  BoxShadow(
                    color: scheme.secondary.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.today_rounded,
                color: scheme.onSecondary,
                size: 24,
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: todayEntryLogged,
              builder: (context, logged, _) {
                if (!logged) return const SizedBox.shrink();
                return Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.primary,
                      border: Border.all(
                        color: scheme.surfaceContainerLow,
                        width: 2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
