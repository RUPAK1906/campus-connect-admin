import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/admin_provider.dart';

// Make sure this matches your filename
import 'admin_event_details.dart'; // We will build this in Phase 3!

class AdminEventsList extends ConsumerWidget {
  const AdminEventsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Correctly watch the Events provider
    final eventsState = ref.watch(adminEventsProvider);

    return eventsState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (events) {
        if (events.isEmpty) {
          return const Center(child: Text('No events found.'));
        }

        return RefreshIndicator(
          // 2. Correctly trigger the Events refresh method
          onRefresh: () => ref.read(adminEventsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                color: Colors.white,
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: event.thumbnailUrl ?? 'https://placehold.co/150',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      // Changed fallback icon to an event calendar icon
                      errorWidget: (context, url, error) => const Icon(Icons.event, size: 40, color: Colors.grey),
                    ),
                  ),
                  title: Text(
                    event.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Added the Venue so admins can quickly see where it's happening
                  subtitle: Text(
                    '${event.category.toUpperCase()} • ${event.venue}',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    // PHASE 3: Navigate to Admin Details Screen
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEventDetailsScreen(event: event)));
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}