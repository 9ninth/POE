import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'event_card.dart';

class EventGrid extends StatelessWidget {
  final List<Event> events;

  const EventGrid({Key? key, required this.events}) : super(key: key);

  int _crossAxisCount(BuildContext context) {
    if (kIsWeb) return 4;
    // fallback: adapt based on width as well
    final width = MediaQuery.of(context).size.width;
    if (width >= 800) return 4; // tablets
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return EventCard(event: events[index]);
              },
              childCount: events.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount(context),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
          ),
        ),
      ],
    );
  }
}
