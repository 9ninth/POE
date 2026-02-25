import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'event_card.dart';

class FeaturedBentoGrid extends StatelessWidget {
  final List<Event> featuredEvents;

  const FeaturedBentoGrid({
    Key? key,
    required this.featuredEvents,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (featuredEvents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              'Featured Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
            ),
          ),
          StaggeredGrid.count(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: List.generate(
              featuredEvents.length,
              (index) {
                final event = featuredEvents[index];
                final isFirstCard = index == 0;

                return StaggeredGridTile.count(
                  crossAxisCellCount: isFirstCard ? 2 : 1,
                  mainAxisCellCount: isFirstCard ? 2 : 1,
                  child: FeaturedEventCard(
                    event: event,
                    isLarge: isFirstCard,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class FeaturedEventCard extends StatefulWidget {
  final Event event;
  final bool isLarge;

  const FeaturedEventCard({
    Key? key,
    required this.event,
    this.isLarge = false,
  }) : super(key: key);

  @override
  _FeaturedEventCardState createState() => _FeaturedEventCardState();
}

class _FeaturedEventCardState extends State<FeaturedEventCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for "Live Now" badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Zoom animation on hover/tap
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.03,
    );

    _zoomAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent details) {
    _zoomController.forward();
  }

  void _onExit(PointerEvent details) {
    _zoomController.reverse();
  }

  void _onTapDown(TapDownDetails details) {
    _zoomController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _zoomController.reverse();
  }

  bool _isEventLiveNow() {
    final now = DateTime.now();
    final eventDate = DateTime.parse('2024-01-01'); // placeholder
    // In production, compare with actual event start time
    return false; // Set to true to show "Live Now" badge
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        child: ScaleTransition(
          scale: _zoomAnimation,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background: Image or Gradient
                Positioned.fill(
                  child: widget.event.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.event.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildGradientBackground(),
                          errorWidget: (context, url, error) =>
                              _buildGradientBackground(),
                        )
                      : _buildGradientBackground(),
                ),

                // Overlay gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // Content: Title and Organization at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(widget.isLarge ? 20 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.event.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: widget.isLarge ? 22 : 14,
                          ),
                          maxLines: widget.isLarge ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.event.organization,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: widget.isLarge ? 14 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // "Live Now" pulsating badge
                if (_isEventLiveNow())
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _LiveNowBadge(pulseAnimation: _pulseAnimation),
                  ),

                // Free Food badge
                if (widget.event.freeFood)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFCC0000),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFCC0000).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        'FREE FOOD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003399), // GSU Blue
            Color(0xFF0052CC), // Lighter GSU Blue
          ],
        ),
      ),
    );
  }
}

class _LiveNowBadge extends StatelessWidget {
  final Animation<double> pulseAnimation;

  const _LiveNowBadge({required this.pulseAnimation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFCC0000),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFCC0000).withOpacity(0.6),
                  blurRadius: 8,
                  spreadRadius: pulseAnimation.value,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 6,
                  height: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  'LIVE NOW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
