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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Artikel',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed_outlined),
            activeIcon: Icon(Icons.rss_feed),
            label: 'Sumber',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            _feedKey.currentState?.refreshFeed();
          }
          if (index == 2) {
            _bookmarkKey.currentState?.fetchBookmarks(showLoading: false);
          }
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.compass),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_border),
            label: 'Bookmark',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
