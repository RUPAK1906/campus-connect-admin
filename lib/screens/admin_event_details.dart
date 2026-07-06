import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event.dart';
import '../providers/admin_provider.dart';
import '../services/admin_service.dart';
import 'create_event_screen.dart';

class AdminEventDetailsScreen extends ConsumerStatefulWidget {
  final Event event;
  const AdminEventDetailsScreen({super.key, required this.event});

  @override
  ConsumerState<AdminEventDetailsScreen> createState() => _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends ConsumerState<AdminEventDetailsScreen> {
  bool _isDeleting = false;
  bool _isLoadingFullData = true; // ✅ Tracks loading state
  late Event _fullEvent; // ✅ Holds the fully populated object

  @override
  void initState() {
    super.initState();
    _fullEvent = widget.event; // Fallback to summary data initially
    _fetchFullDetails();
  }

  // ✅ FETCHES THE MISSING DESCRIPTIONS & LINKS
  Future<void> _fetchFullDetails() async {
    try {
      final data = await AdminService().fetchEventById(widget.event.id);
      if (mounted) {
        setState(() {
          _fullEvent = Event.fromJson(data);
          _isLoadingFullData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFullData = false);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open $urlString')));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Event', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete "${_fullEvent.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              _executeDelete();
            },
            child: const Text('Delete Event'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);
    try {
      await AdminService().deleteEvent(_fullEvent.id);
      ref.read(adminEventsProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted successfully'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatDateTime(DateTime start, DateTime end) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String formatTime(DateTime time) {
      int hour = time.hour;
      String period = 'AM';
      if (hour >= 12) { period = 'PM'; if (hour > 12) hour -= 12; }
      if (hour == 0) hour = 12;
      return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
    }
    return '${months[start.month - 1]} ${start.day}, ${start.year} • ${formatTime(start)} – ${formatTime(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ✅ Edit button is disabled until full data is loaded!
          IconButton(
            icon: Icon(Icons.edit, color: _isLoadingFullData ? Colors.grey : Colors.blue),
            onPressed: _isLoadingFullData ? null : () async {
              final didUpdate = await Navigator.push(
                  context,
                  // Passes FULL data to the editor!
                  MaterialPageRoute(builder: (_) => CreateEventScreen(eventToEdit: _fullEvent))
              );

              if (didUpdate == true) {
                ref.read(adminEventsProvider.notifier).refresh();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isDeleting ? null : _confirmDelete,
          ),
        ],
      ),
      body: _isDeleting || _isLoadingFullData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: _fullEvent.thumbnailUrl ?? 'https://via.placeholder.com/150',
                      width: 80, height: 80, fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fullEvent.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                        const SizedBox(height: 4),
                        Text(_fullEvent.category.toUpperCase(), style: TextStyle(color: Colors.indigo.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  _buildInfoRow(Icons.access_time_filled, 'Date & Time', _formatDateTime(_fullEvent.startTime, _fullEvent.endTime)),
                  const Divider(height: 32, color: Color(0xFFF3F4F6)),
                  _buildInfoRow(Icons.location_on, 'Venue', _fullEvent.venue),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('About Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // ✅ Safely fallback if detailedDescription is empty
            Text(
                (_fullEvent.detailedDescription != null && _fullEvent.detailedDescription!.isNotEmpty)
                    ? _fullEvent.detailedDescription!
                    : _fullEvent.description ?? '',
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6)
            ),
            const SizedBox(height: 24),

            // ✅ NEW: Shows Important Links properly in the Admin view!
            if (_fullEvent.importantLinks != null && _fullEvent.importantLinks!.isNotEmpty) ...[
              const Text('Important Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._fullEvent.importantLinks!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    leading: const Icon(Icons.link, color: Colors.indigo),
                    title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.open_in_new, size: 16),
                    onTap: () => _launchUrl(entry.value.toString()),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.indigo.shade50, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.indigo.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}