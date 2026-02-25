import 'dart:async';

import 'package:flutter/material.dart';

class PantherActionBar extends StatefulWidget {
  final ValueChanged<bool> onFreeFoodToggle;
  final ValueChanged<String> onLocationFilter;
  final bool hasFlashSale;
  final VoidCallback? onNotificationTap;

  const PantherActionBar({
    Key? key,
    required this.onFreeFoodToggle,
    required this.onLocationFilter,
    this.hasFlashSale = false,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  _PantherActionBarState createState() => _PantherActionBarState();
}

class _PantherActionBarState extends State<PantherActionBar> {
  late ScrollController _locationScrollController;
  bool _isFreeFoodEnabled = false;
  String _selectedLocation = 'All';

  final List<String> _locations = [
    'All',
    'Downtown',
    'Clarkston',
    'Alpharetta',
    'Online',
  ];

  @override
  void initState() {
    super.initState();
    _locationScrollController = ScrollController();
  }

  @override
  void dispose() {
    _locationScrollController.dispose();
    super.dispose();
  }

  void _handleFreeFoodToggle(bool value) {
    setState(() {
      _isFreeFoodEnabled = value;
    });
    widget.onFreeFoodToggle(value);
  }

  void _handleLocationChange(String location) {
    setState(() {
      _selectedLocation = location;
    });
    widget.onLocationFilter(location);
  }

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      floating: false,
      delegate: _PantherActionBarDelegate(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Top bar with toggle and notification
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Free Food Tactile Switch
                    TactileFreeFoodSwitch(
                      isEnabled: _isFreeFoodEnabled,
                      onChanged: _handleFreeFoodToggle,
                    ),
                    // Notification Bell
                    NotificationBell(
                      hasFlashSale: widget.hasFlashSale,
                      onTap: widget.onNotificationTap,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Location Filter Chips
              SizedBox(
                height: 50,
                child: ListView.builder(
                  controller: _locationScrollController,
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _locations.length,
                  itemBuilder: (context, index) {
                    final location = _locations[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedFilterChip(
                        label: location,
                        isSelected: _selectedLocation == location,
                        onSelected: () => _handleLocationChange(location),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantherActionBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PantherActionBarDelegate({required this.child});

  @override
  double get minExtent => 130;

  @override
  double get maxExtent => 130;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_PantherActionBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

/// Tactile Free Food Switch with GSU Red glow
class TactileFreeFoodSwitch extends StatefulWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const TactileFreeFoodSwitch({
    Key? key,
    required this.isEnabled,
    required this.onChanged,
  }) : super(key: key);

  @override
  _TactileFreeFoodSwitchState createState() => _TactileFreeFoodSwitchState();
}

class _TactileFreeFoodSwitchState extends State<TactileFreeFoodSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTap() {
    _scaleController.forward(from: 0.95);
    HapticFeedback.mediumImpact();
    widget.onChanged(!widget.isEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade100,
          ),
          child: Container(
            width: 60,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: widget.isEnabled
                  ? const Color(0xFFCC0000)
                  : Colors.grey.shade300,
              boxShadow: widget.isEnabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFFCC0000).withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: AnimatedAlign(
              alignment: widget.isEnabled
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: widget.isEnabled ? 1.0 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        widget.isEnabled ? Icons.check : Icons.close,
                        size: 16,
                        color: widget.isEnabled
                            ? const Color(0xFFCC0000)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated Filter Chip
class AnimatedFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const AnimatedFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  }) : super(key: key);

  @override
  _AnimatedFilterChipState createState() => _AnimatedFilterChipState();
}

class _AnimatedFilterChipState extends State<AnimatedFilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _colorAnimation = ColorTween(
      begin: Colors.grey.shade200,
      end: const Color(0xFFCC0000),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFilterChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onSelected,
        child: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _colorAnimation.value,
                border: Border.all(
                  color: widget.isSelected
                      ? const Color(0xFFCC0000)
                      : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFCC0000).withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Notification Bell with Badge and Shake Animation
class NotificationBell extends StatefulWidget {
  final bool hasFlashSale;
  final VoidCallback? onTap;

  const NotificationBell({
    Key? key,
    required this.hasFlashSale,
    this.onTap,
  }) : super(key: key);

  @override
  _NotificationBellState createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticInOut),
    );

    if (widget.hasFlashSale) {
      _startShakeAnimation();
    }
  }

  @override
  void didUpdateWidget(NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasFlashSale && !oldWidget.hasFlashSale) {
      _startShakeAnimation();
    } else if (!widget.hasFlashSale && oldWidget.hasFlashSale) {
      _stopShakeAnimation();
    }
  }

  void _startShakeAnimation() {
    _shakeTimer?.cancel();
    _shakeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        _shakeController.forward(from: 0);
      }
    });
  }

  void _stopShakeAnimation() {
    _shakeTimer?.cancel();
    _shakeController.stop();
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              // Calculate shake offset
              final offset =
                  (_shakeAnimation.value - 0.5) * 8; // -4 to +4 pixels
              return Transform.translate(
                offset: Offset(offset, 0),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 28,
                  color: Colors.grey.shade700,
                ),
              );
            },
          ),
          if (widget.hasFlashSale)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFCC0000),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCC0000).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
