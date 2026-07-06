import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notice.dart';
import '../models/event.dart';
import '../services/admin_service.dart';

// --- NOTICES PROVIDER ---
class AdminNoticesNotifier extends AsyncNotifier<List<Notice>> {
  @override
  FutureOr<List<Notice>> build() async {
    return _fetchNotices();
  }

  Future<List<Notice>> _fetchNotices() async {
    final rawData = await AdminService().fetchAdminNotices();
    return rawData.map((json) => Notice.fromJson(json)).toList();
  }

  // Call this after deleting/editing a notice!
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchNotices());
  }
}

final adminNoticesProvider = AsyncNotifierProvider<AdminNoticesNotifier, List<Notice>>(AdminNoticesNotifier.new);


// --- EVENTS PROVIDER ---
class AdminEventsNotifier extends AsyncNotifier<List<Event>> {
  @override
  FutureOr<List<Event>> build() async {
    return _fetchEvents();
  }

  Future<List<Event>> _fetchEvents() async {
    final rawData = await AdminService().fetchAdminEvents();
    return rawData.map((json) => Event.fromJson(json)).toList();
  }

  // Call this after deleting/editing an event!
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchEvents());
  }
}

final adminEventsProvider = AsyncNotifierProvider<AdminEventsNotifier, List<Event>>(AdminEventsNotifier.new);