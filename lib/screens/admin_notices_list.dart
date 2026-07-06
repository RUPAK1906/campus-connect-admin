import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/admin_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'admin_notice_details.dart'; // We will build this in Phase 3!

class AdminNoticesList extends ConsumerWidget {
  const AdminNoticesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Modern Riverpod watching AsyncValue
    final noticesState = ref.watch(adminNoticesProvider);

    return noticesState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (notices) {
        if (notices.isEmpty) {
          return const Center(child: Text('No notices found.'));
        }

        return RefreshIndicator(
          // Triggers our new AsyncNotifier refresh method!
          onRefresh: () => ref.read(adminNoticesProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
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
                      imageUrl: notice.thumbnailUrl ?? 'https://placehold.co/150',
                      width: 60, height: 60, fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.image, size: 40),
                    ),
                  ),
                  title: Text(notice.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(notice.category, style: TextStyle(color: Colors.blue.shade700)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // PHASE 3: Navigate to Admin Details Screen
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminNoticeDetailsScreen(notice: notice)));
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