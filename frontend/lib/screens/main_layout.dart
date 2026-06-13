import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'feed_screen.dart';
import 'explore_screen.dart';
import 'bookmark_screen.dart';
import 'profile_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'admin_articles_screen.dart';
import 'admin_sources_screen.dart';
import 'admin_settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final GlobalKey<BookmarkScreenState> _bookmarkKey = GlobalKey<BookmarkScreenState>();
  final GlobalKey<FeedScreenState> _feedKey = GlobalKey<FeedScreenState>();

  void _onTabSelected(int index) {
    if (index == 0) {
      _feedKey.currentState?.refreshFeed();
    }
    if (index == 2) {
      _bookmarkKey.currentState?.fetchBookmarks(showLoading: false);
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final isAdmin = auth.isAdmin;

    if (isAdmin) {
      return _buildAdminLayout();
    }
    return _buildUserLayout();
  }

  Widget _buildAdminLayout() {
    final adminScreens = [
      AdminDashboardScreen(
        onNavigateTab: (index) => setState(() => _currentIndex = index),
      ),
      const AdminUsersScreen(),
      const AdminArticlesScreen(),
      const AdminSourcesScreen(),
      const AdminSettingsScreen(),
    ];

    if (_currentIndex >= adminScreens.length) {
      _currentIndex = adminScreens.length - 1;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: adminScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Artikel',
          ),
          NavigationDestination(
            icon: Icon(Icons.rss_feed_outlined),
            selectedIcon: Icon(Icons.rss_feed),
            label: 'Sumber',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildUserLayout() {
    final userScreens = [
      FeedScreen(key: _feedKey),
      const ExploreScreen(),
      BookmarkScreen(key: _bookmarkKey),
      const ProfileScreen(),
    ];

    if (_currentIndex >= userScreens.length) {
      _currentIndex = userScreens.length - 1;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: userScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(CupertinoIcons.compass),
            selectedIcon: Icon(CupertinoIcons.compass_fill),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmark',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
