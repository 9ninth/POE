import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class Event {
  final String title;
  final String organization;
  final String imageUrl;
  final bool freeFood;

  Event({
    required this.title,
    required this.organization,
    required this.imageUrl,
    this.freeFood = false,
  });
}

class EventCard extends StatefulWidget {
  final Event event;

  const EventCard({Key? key, required this.event}) : super(key: key);

  @override
  _EventCardState createState() => _EventCardState();
}

class _EventCardState extends State<EventCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 1.0,
      upperBound: 1.05,
    );
    _zoomAnimation = CurvedAnimation(
      parent: _zoomController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
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
                // background image
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.event.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: Colors.grey.shade300),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                // glass overlay at bottom 30%
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Container(
                    color: Colors.transparent,
                    child: BackdropFilter(
                      filter:
                          ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(12),
                        color: Colors.black.withOpacity(0.2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.event.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.event.organization,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Free food badge
                if (widget.event.freeFood)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _FreeFoodBadge(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeFoodBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFCC0000), width: 1.5),
        color: Colors.white.withOpacity(0.15),
      ),
      child: const Text(
        'FREE FOOD',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
