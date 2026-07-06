import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add this
import '../services/admin_service.dart';
import 'create_event_screen.dart';
import 'login_screen.dart';
import 'create_notice_screen.dart';
// We will create these two files below!
import 'admin_notices_list.dart';
import 'admin_events_list.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedIndex = 0;

  void _handleLogout() {
    AdminService().logout();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Campus Connect Admin'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // WEB LAYOUT
            return Row(
              children: [
                NavigationRail(
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.article), label: Text('Notices')),
                    NavigationRailDestination(icon: Icon(Icons.event), label: Text('Events')),
                  ],
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                    child: Center(
                        child: _selectedIndex == 0 ? const AdminNoticesList() : const AdminEventsList()
                    )
                ),
              ],
            );
          } else {
            // MOBILE LAYOUT (Shows the actual lists!)
            return _selectedIndex == 0 ? const AdminNoticesList() : const AdminEventsList();
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
        onPressed: () {
          if (_selectedIndex == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateNoticeScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateEventScreen()));
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_selectedIndex == 0 ? 'New Notice' : 'New Event'),
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 800
          ? BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1D4ED8),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Notices'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
        ],
      )
          : null,
    );
  }
}