import 'dart:convert';
import 'dart:typed_data'; // Needed for cross-platform file bytes
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AdminService {
  final _supabase = Supabase.instance.client;
  final String _nodeApiUrl = 'https://campus-connect-api-z6og.onrender.com'; // Change for production

  // 1. AUTHENTICATION
  Future<void> login(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  void logout() async {
    await _supabase.auth.signOut();
  }

  // 2. CROSS-PLATFORM IMAGE UPLOAD (Unified for Web & Mobile)
  Future<String?> pickAndUploadImage() async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      String? publicUrl;

      final ImagePicker picker = ImagePicker();

      // This single line opens the mobile gallery OR the web file explorer!
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

      if (image != null) {
        // readAsBytes() safely extracts the image data whether on Web or Mobile
        final Uint8List fileBytes = await image.readAsBytes();

        // Upload the raw bytes to Supabase Storage
        await _supabase.storage.from('thumbnails').uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'), // Ensures it loads properly in browsers
        );

        // Retrieve the public URL to save to your database
        publicUrl = _supabase.storage.from('thumbnails').getPublicUrl(fileName);
      }
      return publicUrl;
    } catch (e) {
      throw Exception('Image upload failed: $e');
    }
  }

  // 3. EXPRESS API INTEGRATION (CREATE NOTICE)
  Future<void> createNotice(Map<String, dynamic> noticeData) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');

    final response = await http.post(
      Uri.parse('$_nodeApiUrl/notices'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}', // Pass Supabase JWT to Node
      },
      body: jsonEncode(noticeData),
    );

    if (response.statusCode != 201) throw Exception(response.body);
  }

  // --- FETCH DATA ---
  Future<List<dynamic>> fetchAdminNotices() async {
    final response = await http.get(Uri.parse('$_nodeApiUrl/notices'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body); // Let the model parse it in the provider
    } else {
      throw Exception('Failed to fetch notices');
    }
  }

  Future<List<dynamic>> fetchAdminEvents() async {
    final response = await http.get(Uri.parse('$_nodeApiUrl/events'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch events');
    }
  }

  // 4. EXPRESS API INTEGRATION (DELETE NOTICE)
  Future<void> deleteNotice(String noticeId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');

    final response = await http.delete(
      Uri.parse('$_nodeApiUrl/notices/$noticeId'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) throw Exception('Failed to delete notice');
  }

  // --- EXPRESS API INTEGRATION (UPDATE NOTICE) ---
  Future<void> updateNotice(String noticeId, Map<String, dynamic> noticeData) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');

    final response = await http.put(
      Uri.parse('$_nodeApiUrl/notices/$noticeId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode(noticeData),
    );

    if (response.statusCode != 200) throw Exception(response.body);
  }

  // --- EXPRESS API INTEGRATION (UPDATE EVENT) ---
  Future<void> updateEvent(String eventId, Map<String, dynamic> eventData) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');

    final response = await http.put(
      Uri.parse('$_nodeApiUrl/events/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode != 200) throw Exception(response.body);
  }

  // 5. EXPRESS API INTEGRATION (CREATE EVENT)
  Future<void> createEvent(Map<String, dynamic> eventData) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');

    final response = await http.post(
      Uri.parse('$_nodeApiUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${session.accessToken}',
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode != 201) throw Exception(response.body);
  }
  // Add these inside your AdminService class:

  Future<Map<String, dynamic>> fetchNoticeById(String id) async {
    final response = await http.get(Uri.parse('$_nodeApiUrl/notices/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch full notice details');
    }
  }

  Future<Map<String, dynamic>> fetchEventById(String id) async {
    final response = await http.get(Uri.parse('$_nodeApiUrl/events/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch full event details');
    }
  }

  // 6. EXPRESS API INTEGRATION (DELETE EVENT)
  Future<void> deleteEvent(String eventId) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not logged in');

    final response = await http.delete(
      Uri.parse('$_nodeApiUrl/events/$eventId'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.statusCode != 200) throw Exception('Failed to delete event');
  }
}