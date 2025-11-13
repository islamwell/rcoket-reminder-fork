import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Bottom Navigation Bar implementing Islamic minimalism design
/// with adaptive behavior and contextual hiding during audio playback
class CustomBottomBar extends StatefulWidget {
  /// Current selected index
  final int currentIndex;

  /// Callback when a tab is selected
  final ValueChanged<int> onTap;

  /// Whether to hide the bottom bar (for audio playback or other contexts)
  final bool isHidden;

  /// Custom background color
  final Color? backgroundColor;

  /// Whether to show labels
  final bool showLabels;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isHidden = false,
    this.backgroundColor,
    this.showLabels = true,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(CustomBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHidden != oldWidget.isHidden) {
      if (widget.isHidden) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 76,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildNavigationItems(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the navigation items with consistent icons and routes
  List<Widget> _buildNavigationItems(BuildContext context) {
    final items = [
      _NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: 'Home',
        route: '/dashboard',
        index: 0,
      ),
      _NavigationItem(
        icon: Icons.library_music_outlined,
        activeIcon: Icons.library_music_rounded,
        label: 'Audio',
        route: '/audio-library',
        index: 1,
      ),
      _NavigationItem(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications_rounded,
        label: 'Reminders',
        route: '/reminder-management',
        index: 2,
      ),
      _NavigationItem(
        icon: Icons.insights_outlined,
        activeIcon: Icons.insights_rounded,
        label: 'Progress',
        route: '/progress-history',
        index: 3,
      ),
    ];

    return items.map((item) => _buildNavigationButton(context, item)).toList();
  }

  /// Builds individual navigation button with smooth transitions
  Widget _buildNavigationButton(BuildContext context, _NavigationItem item) {
    final theme = Theme.of(context);
    final isSelected = widget.currentIndex == item.index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          widget.onTap(item.index);
          _navigateToRoute(context, item.route);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  key: ValueKey(isSelected),
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              if (widget.showLabels) ...[
                SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 200),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  child: Text(item.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Navigates to the specified route with proper handling
  void _navigateToRoute(BuildContext context, String route) {
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != route) {
      // Use pushReplacementNamed to replace current route in bottom navigation
      Navigator.pushReplacementNamed(context, route);
    }
  }
}

/// Internal class to represent navigation items
class _NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;
  final int index;

  const _NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
    required this.index,
  });
}

/// Extension to provide easy access to CustomBottomBar in any widget
extension CustomBottomBarExtension on Widget {
  /// Wraps the widget with a Scaffold that includes CustomBottomBar
  Widget withCustomBottomBar({
    required int currentIndex,
    required ValueChanged<int> onTap,
    bool isHidden = false,
    Color? backgroundColor,
    bool showLabels = true,
  }) {
    return Builder(
      builder: (context) => Scaffold(
        body: this,
        bottomNavigationBar: CustomBottomBar(
          currentIndex: currentIndex,
          onTap: onTap,
          isHidden: isHidden,
          backgroundColor: backgroundColor,
          showLabels: showLabels,
        ),
      ),
    );
  }
}
