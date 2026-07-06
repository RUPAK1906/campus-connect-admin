import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/notice.dart';
import '../providers/admin_provider.dart';
import '../services/admin_service.dart';
import 'create_notice_screen.dart';

class AdminNoticeDetailsScreen extends ConsumerStatefulWidget {
  final Notice notice;
  const AdminNoticeDetailsScreen({super.key, required this.notice});

  @override
  ConsumerState<AdminNoticeDetailsScreen> createState() => _AdminNoticeDetailsScreenState();
}

class _AdminNoticeDetailsScreenState extends ConsumerState<AdminNoticeDetailsScreen> {
  bool _isDeleting = false;
  bool _isLoadingFullData = true;
  late Notice _fullNotice;

  @override
  void initState() {
    super.initState();
    _fullNotice = widget.notice; // Fallback to summary data initially
    _fetchFullDetails();
  }

  // ✅ THIS FETCHES THE MISSING DESCRIPTIONS & LINKS
  Future<void> _fetchFullDetails() async {
    try {
      final data = await AdminService().fetchNoticeById(widget.notice.id);
      if (mounted) {
        setState(() {
          _fullNotice = Notice.fromJson(data);
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
        title: const Text('Delete Notice', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${_fullNotice.title}"?\n\nThis action cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
            onPressed: () async { Navigator.pop(ctx); _executeDelete(); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDelete() async {
    setState(() => _isDeleting = true);
    try {
      await AdminService().deleteNotice(_fullNotice.id);
      ref.read(adminNoticesProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted successfully'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red));
        setState(() => _isDeleting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () => Navigator.pop(context)),
        actions: [
          // Edit button is disabled until full data is loaded to prevent sending empty data to edit screen
          IconButton(
            icon: Icon(Icons.edit, color: _isLoadingFullData ? Colors.grey : Colors.blue),
            onPressed: _isLoadingFullData ? null : () async {
              final didUpdate = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateNoticeScreen(noticeToEdit: _fullNotice)) // Passes FULL data!
              );
              if (didUpdate == true) {
                ref.read(adminNoticesProvider.notifier).refresh();
                if (mounted) Navigator.pop(context);
              }
            },
          ),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _isDeleting ? null : _confirmDelete),
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
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: _fullNotice.thumbnailUrl ?? 'https://via.placeholder.com/150', width: 80, height: 80, fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(width: 80, height: 80, color: Colors.blue.shade50, child: const Icon(Icons.article)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(_fullNotice.category.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                        ),
                        const SizedBox(height: 8),
                        Text(_fullNotice.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
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
                  _buildInfoRow(Icons.calendar_month, 'Posted On', _formatDate(_fullNotice.createdAt)),
                  const Divider(height: 32, color: Color(0xFFF3F4F6)),
                  _buildInfoRow(Icons.person, 'Author', _fullNotice.authorName),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Notice Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
                (_fullNotice.detailedDescription != null && _fullNotice.detailedDescription!.isNotEmpty)
                    ? _fullNotice.detailedDescription!
                    : _fullNotice.content,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade600, height: 1.6)
            ),
            const SizedBox(height: 24),
            if (_fullNotice.importantLinks != null && _fullNotice.importantLinks!.isNotEmpty) ...[
              const Text('Important Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._fullNotice.importantLinks!.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    leading: const Icon(Icons.link, color: Colors.blue),
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
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: Icon(icon, color: Colors.blue.shade700, size: 20)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ],
    );
  }
}