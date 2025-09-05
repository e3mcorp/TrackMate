import 'package:trackmate/locale/locales.dart';
import 'package:trackmate/screens/settings.dart';
import 'package:trackmate/screens/tracker_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // ✅ CAMBIO: Da salomon a google_nav_bar
import 'map.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State createState() {
    return MainMenuState();
  }
}

/// Class to represent menu options
class MenuOption {
  /// Widget to represent the menu option
  late Widget Function(BuildContext context) builder;

  /// Label of the option
  /// Labels are only translated in runtime.
  late String label;

  /// Icon to display in the options
  late IconData icon;

  MenuOption({
    Widget Function(BuildContext context)? builder,
    String? label,
    IconData? icon,
  }) {
    this.builder = builder ?? (BuildContext builder) => Container();
    this.label = label ?? '';
    this.icon = icon ?? Icons.home;
  }
}

class MainMenuState extends State {
  /// Index of the selected widget
  int selectedIndex = 0;

  /// Options available in the menu
  static List<MenuOption> options = [
    MenuOption(
      label: 'trackers',
      builder: (BuildContext context) => const TrackerListScreen(),
      icon: Icons.gps_fixed,
    ),
    MenuOption(
      label: 'map',
      builder: (BuildContext context) => const MapScreen(),
      icon: Icons.map,
    ),
    MenuOption(
      label: 'settings',
      builder: (BuildContext context) => const SettingsScreen(),
      icon: Icons.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ✅ CAMBIO: Creazione lista GButton per GNav
    List<GButton> buttons = [];

    for (int i = 0; i < options.length; i++) {
      Color selectedColor;

      // Assegnazione colori diversi per ogni tab usando il ColorScheme Material 3
      switch (i) {
        case 0: // Trackers
          selectedColor = colorScheme.primary;
          break;
        case 1: // Map
          selectedColor = colorScheme.secondary;
          break;
        case 2: // Settings
          selectedColor = colorScheme.tertiary;
          break;
        default:
          selectedColor = colorScheme.primary;
      }

      buttons.add(
        GButton( // ✅ CAMBIO: Da SalomonBottomBarItem a GButton
          icon: options[i].icon,
          text: Locales.get(options[i].label, context),
          backgroundColor: selectedColor.withOpacity(0.2),
          iconActiveColor: selectedColor,
          textColor: selectedColor,
          iconSize: 26.0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          gap: 8,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Locales.get('carTracker', context),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<int>(selectedIndex),
          child: options.elementAt(selectedIndex).builder(context),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GNav( // ✅ CAMBIO: Da SalomonBottomBar a GNav
              gap: 8,
              activeColor: colorScheme.primary,
              iconSize: 26,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: colorScheme.primaryContainer.withOpacity(0.2),
              color: colorScheme.onSurfaceVariant,
              tabs: buttons, // ✅ CAMBIO: Da items a tabs
              selectedIndex: selectedIndex,
              onTabChange: (index) { // ✅ CAMBIO: Da onTap a onTabChange
                if (selectedIndex != index) {
                  // Feedback tattile leggero
                  HapticFeedback.selectionClick();
                  setState(() {
                    selectedIndex = index;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
