import 'package:trackmate/locale/locales.dart';
import 'package:trackmate/screens/settings.dart';
import 'package:trackmate/screens/tracker_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'map.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() {
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

class MainMenuState extends State<MainMenu> {
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

    // Creazione lista items per SalomonBottomBar con Material 3 theming
    List<SalomonBottomBarItem> buttons = [];

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
        SalomonBottomBarItem(
          icon: Icon(
            options[i].icon,
            size: 26.0,
          ),
          title: Text(
            Locales.get(options[i].label, context),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          selectedColor: selectedColor,
          unselectedColor: colorScheme.onSurfaceVariant,
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
          child: SalomonBottomBar(
            margin: EdgeInsets.zero,
            items: buttons,
            currentIndex: selectedIndex,
            backgroundColor: Colors.transparent,
            // Personalizzazione colori per Material 3
            unselectedItemColor: colorScheme.onSurfaceVariant,
            // Animazione più fluida
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            // Personalizzazione forma degli item attivi
            itemShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onTap: (int index) {
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
    );
  }
}
