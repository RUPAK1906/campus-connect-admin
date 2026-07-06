import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/admin_service.dart';

class CreateEventScreen extends StatefulWidget {
  final Event? eventToEdit; // 👈 Accepts an existing event!
  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _longDescController = TextEditingController();
  final _venueController = TextEditingController();
  final _mapLinkController = TextEditingController();
  final List<Map<String, TextEditingController>> _resourceLinks = [];

  String _selectedCategory = 'technology';
  String? _thumbnailUrl;
  DateTime? _startTime;
  DateTime? _endTime;

  bool _isUploading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 👇 AUTO-FILL DATA IF EDITING
    if (widget.eventToEdit != null) {
      final event = widget.eventToEdit!;
      _titleController.text = event.title;
      _shortDescController.text = event.description ?? '';
      _longDescController.text = event.detailedDescription ?? '';
      _venueController.text = event.venue;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _selectedCategory = event.category.toLowerCase();
      _thumbnailUrl = event.thumbnailUrl;

      // Extract existing Important Links
      if (event.importantLinks != null) {
        event.importantLinks!.forEach((key, value) {
          if (key.toLowerCase() == 'location') {
            _mapLinkController.text = value.toString();
          } else {
            _resourceLinks.add({
              'title': TextEditingController(text: key),
              'url': TextEditingController(text: value.toString()),
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescController.dispose();
    _longDescController.dispose();
    _venueController.dispose();
    _mapLinkController.dispose();
    for (var link in _resourceLinks) {
      link['title']!.dispose();
      link['url']!.dispose();
    }
    super.dispose();
  }

  Future<void> _handleImagePick() async {
    setState(() => _isUploading = true);
    try {
      final url = await AdminService().pickAndUploadImage();
      if (url != null) setState(() => _thumbnailUrl = url);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final pickedDate = await showDatePicker(
      context: context, initialDate: _startTime ?? DateTime.now(),
      firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context, initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
          if (isStart) {
            _startTime = selectedDateTime;
            _endTime ??= _startTime!.add(const Duration(hours: 1));
          } else {
            _endTime = selectedDateTime;
          }
        });
      }
    }
  }

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

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select times'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      Map<String, dynamic> importantLinks = {};
      if (_mapLinkController.text.trim().isNotEmpty) importantLinks['Location'] = _mapLinkController.text.trim();
      for (var link in _resourceLinks) {
        if (link['title']!.text.trim().isNotEmpty && link['url']!.text.trim().isNotEmpty) {
          importantLinks[link['title']!.text.trim()] = link['url']!.text.trim();
        }
      }

      final payload = {
        'title': _titleController.text.trim(),
        'description': _shortDescController.text.trim(),
        'category': _selectedCategory,
        'venue': _venueController.text.trim(),
        'start_time': _startTime!.toIso8601String(),
        'end_time': _endTime!.toIso8601String(),
        'detailed_description': _longDescController.text.trim(),
        'thumbnail': _thumbnailUrl,
        'important_links': importantLinks,
      };

      // 👇 DYNAMIC LOGIC: Update or Create
      if (widget.eventToEdit != null) {
        await AdminService().updateEvent(widget.eventToEdit!.id, payload);
      } else {
        await AdminService().createEvent(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.eventToEdit != null ? 'Event Updated Successfully!' : 'Event Created Successfully!'),
            backgroundColor: Colors.green
        ));
        Navigator.pop(context, true); // 👈 Return true on success
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Select Date';
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    int hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    String min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} • $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.eventToEdit != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(title: Text(isEditing ? 'Edit Event' : 'Create Event', style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.white),
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
                  const Text('Event Thumbnail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _isUploading ? null : _handleImagePick,
                    child: Container(
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300),
                        image: _thumbnailUrl != null ? DecorationImage(image: NetworkImage(_thumbnailUrl!), fit: BoxFit.cover) : null,
                      ),
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : _thumbnailUrl == null
                          ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Tap to upload thumbnail', style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ) : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    items: ['technology', 'sports', 'cultural', 'academics'].map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _shortDescController,
                    decoration: const InputDecoration(labelText: 'Short Description', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    maxLines: 2,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _longDescController,
                    decoration: const InputDecoration(labelText: 'Detailed Description', border: OutlineInputBorder(), alignLabelWithHint: true, filled: true, fillColor: Colors.white),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  const Text('Date & Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(true),
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(_formatDateTime(_startTime)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.white, side: BorderSide(color: _startTime == null ? Colors.grey.shade400 : Colors.blue.shade700)),
                        ),
                      ),
                      const SizedBox(width: 8), const Text('To'), const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickDateTime(false),
                          icon: const Icon(Icons.schedule, size: 18),
                          label: Text(_formatDateTime(_endTime)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.white, side: BorderSide(color: _endTime == null ? Colors.grey.shade400 : Colors.blue.shade700)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Venue & Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _venueController,
                    decoration: const InputDecoration(labelText: 'Venue Name', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _mapLinkController,
                    decoration: const InputDecoration(labelText: 'Google Maps Link (Optional)', prefixIcon: Icon(Icons.map), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Important Links', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_resourceLinks.length < 3)
                        TextButton.icon(onPressed: _addResourceLink, icon: const Icon(Icons.add, size: 18), label: const Text('Add Link'))
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
                                TextFormField(controller: _resourceLinks[index]['title'], decoration: const InputDecoration(labelText: 'Link Title (e.g., Registration)', isDense: true)),
                                const SizedBox(height: 8),
                                TextFormField(controller: _resourceLinks[index]['url'], decoration: const InputDecoration(labelText: 'URL (https://...)', isDense: true)),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeResourceLink(index))
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitEvent,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1D4ED8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(isEditing ? 'Save Changes' : 'Publish Event', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}