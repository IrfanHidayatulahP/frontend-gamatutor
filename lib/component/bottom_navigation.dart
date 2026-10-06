import 'package:flutter/material.dart';

class BottomNavigationItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String route;

  const BottomNavigationItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.route,
  });
}

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double height;
  final bool showLabels;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8,
    this.height = 80,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = backgroundColor ?? colorScheme.surface;
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor = unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == currentIndex;

            return Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: Icon(
                            isSelected && item.activeIcon != null
                                ? item.activeIcon!
                                : item.icon,
                            key: ValueKey(isSelected),
                            size: 24,
                            color: isSelected ? selectedColor : unselectedColor,
                          ),
                        ),
                        if (showLabels) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected ? selectedColor : unselectedColor,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FloatingBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final List<BottomNavigationItem> items;
  final ValueChanged<int> onTap;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const FloatingBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.margin,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bgColor = backgroundColor ?? colorScheme.surface;
    final selectedColor = selectedItemColor ?? colorScheme.primary;
    final unselectedColor = unselectedItemColor ?? colorScheme.onSurface.withValues(alpha: 0.5);

    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(borderRadius - 8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(borderRadius - 8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: Icon(
                          isSelected && item.activeIcon != null
                              ? item.activeIcon!
                              : item.icon,
                          key: ValueKey(isSelected),
                          size: 24,
                          color: isSelected ? selectedColor : unselectedColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isSelected ? selectedColor : unselectedColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class BottomNavigationController extends ChangeNotifier {
  int _currentIndex = 0;
  final List<BottomNavigationItem> items;

  BottomNavigationController({required this.items});

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (index >= 0 && index < items.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void next() {
    if (_currentIndex < items.length - 1) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }
}

class ControlledBottomNavigation extends StatelessWidget {
  final BottomNavigationController controller;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double elevation;
  final double height;
  final bool showLabels;
  final bool floating;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const ControlledBottomNavigation({
    super.key,
    required this.controller,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.elevation = 8,
    this.height = 80,
    this.showLabels = true,
    this.floating = false,
    this.margin,
    this.borderRadius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (floating) {
          return FloatingBottomNavigation(
            currentIndex: controller.currentIndex,
            items: controller.items,
            onTap: controller.setIndex,
            backgroundColor: backgroundColor,
            selectedItemColor: selectedItemColor,
            unselectedItemColor: unselectedItemColor,
            margin: margin,
            borderRadius: borderRadius,
          );
        }

        return BottomNavigation(
          currentIndex: controller.currentIndex,
          items: controller.items,
          onTap: controller.setIndex,
          backgroundColor: backgroundColor,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          elevation: elevation,
          height: height,
          showLabels: showLabels,
        );
      },
    );
  }
}