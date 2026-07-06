import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/admin_service.dart';

class CreateNoticeScreen extends StatefulWidget {
  final Notice? noticeToEdit;
  const CreateNoticeScreen({super.key, this.noticeToEdit});

  @override
  State<CreateNoticeScreen> createState() => _CreateNoticeScreenState();
}

class _CreateNoticeScreenState extends State<CreateNoticeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _detailedDescController = TextEditingController();

  // ✅ Added List for dynamic links
  final List<Map<String, TextEditingController>> _resourceLinks = [];

  String _selectedCategory = 'academics';
  String? _thumbnailUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.noticeToEdit != null) {
      final notice = widget.noticeToEdit!;
      _titleController.text = notice.title;
      _contentController.text = notice.content;
      _detailedDescController.text = notice.detailedDescription ?? '';

      // Safety lowercase check for dropdowns!
      final fetchedCategory = notice.category.toLowerCase();
      _selectedCategory = ['academics', 'sports', 'technology', 'hostel'].contains(fetchedCategory)
          ? fetchedCategory
          : 'academics';

      _thumbnailUrl = notice.thumbnailUrl;

      // ✅ AUTO-FILL IMPORTANT LINKS IF EDITING
      if (notice.importantLinks != null) {
        notice.importantLinks!.forEach((key, value) {
          _resourceLinks.add({
            'title': TextEditingController(text: key),
            'url': TextEditingController(text: value.toString()),
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _detailedDescController.dispose();
    for (var link in _resourceLinks) {
      link['title']!.dispose();
      link['url']!.dispose();
    }
    super.dispose();
  }

  // ✅ Methods to add/remove links dynamically
  void _addResourceLink() {
    if (_resourceLinks.length < 3) {
      setState(() => _resourceLinks.add({'title': TextEditingController(), 'url': TextEditingController()}));
    }
  }

  void _removeResourceLink(int index) {
    setState(() {
      _resourceLinks[index]['title']!.dispose();
      _resourceLinks[index]['url']!.dispose();
      _resourceLinks.removeAt(index);
    });
  }

  Future<void> _handleImagePick() async {
    setState(() => _isUploading = true);
    try {
      final url = await AdminService().pickAndUploadImage();
      if (url != null) {
        setState(() => _thumbnailUrl = url);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      // ✅ Compile the links into a map for the API
      Map<String, dynamic> importantLinks = {};
      for (var link in _resourceLinks) {
        if (link['title']!.text.trim().isNotEmpty && link['url']!.text.trim().isNotEmpty) {
          importantLinks[link['title']!.text.trim()] = link['url']!.text.trim();
        }
      }

      final payload = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'detailed_description': _detailedDescController.text.trim(),
        'thumbnail': _thumbnailUrl,
        'important_links': importantLinks, // ✅ Pass compiled links to Supabase
      };

      if (widget.noticeToEdit != null) {
        await AdminService().updateNotice(widget.noticeToEdit!.id, payload);
      } else {
        await AdminService().createNotice(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.noticeToEdit != null ? 'Notice Updated Successfully!' : 'Notice Created Successfully!'),
            backgroundColor: Colors.green
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noticeToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Notice' : 'Create Notice', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notice Thumbnail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isUploading ? null : _handleImagePick,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _thumbnailUrl != null
                            ? DecorationImage(image: NetworkImage(_thumbnailUrl!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _thumbnailUrl == null
                          ? Center(child: Text('Tap to upload thumbnail', style: TextStyle(color: Colors.grey.shade500)))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    items: ['academics', 'sports', 'technology', 'hostel'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(labelText: 'Short Description', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    maxLines: 2,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _detailedDescController,
                    decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder(), alignLabelWithHint: true, filled: true, fillColor: Colors.white),
                    maxLines: 6,
                  ),
                  const SizedBox(height: 24),

                  // ✅ NEW: Important Links Section UI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Important Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_resourceLinks.length < 3)
                        TextButton.icon(
                            onPressed: _addResourceLink,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Link')
                        )
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_resourceLinks.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                TextFormField(
                                    controller: _resourceLinks[index]['title'],
                                    decoration: const InputDecoration(labelText: 'Link Title (e.g., Syllabus PDF)', isDense: true)
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                    controller: _resourceLinks[index]['url'],
                                    decoration: const InputDecoration(labelText: 'URL (https://...)', isDense: true)
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _removeResourceLink(index)
                          )
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitNotice,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEditing ? 'Save Changes' : 'Publish Notice', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}