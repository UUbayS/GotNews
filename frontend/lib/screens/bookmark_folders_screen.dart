import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/news_service.dart';
import '../widgets/empty_state.dart';
import 'bookmark_folder_detail_screen.dart';

class BookmarkFoldersScreen extends StatefulWidget {
  const BookmarkFoldersScreen({super.key});

  @override
  State<BookmarkFoldersScreen> createState() => _BookmarkFoldersScreenState();
}

class _BookmarkFoldersScreenState extends State<BookmarkFoldersScreen> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() => _isLoading = true);
    try {
      final folders = await NewsService.getBookmarkFolders();
      if (mounted) {
        setState(() {
          _folders = folders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('New Folder', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              try {
                await NewsService.createBookmarkFolder(name);
                _loadFolders();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Bookmark Folders', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: textColor),
            onPressed: _showCreateFolderDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _folders.isEmpty
              ? EmptyState.noFolders(onCreate: _showCreateFolderDialog)
              : RefreshIndicator(
                  onRefresh: _loadFolders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _folders.length,
                    itemBuilder: (context, index) {
                      final folder = _folders[index];
                      return Dismissible(
                        key: Key(folder['id']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) async {
                          await NewsService.deleteBookmarkFolder(folder['id']);
                          _loadFolders();
                        },
                        child: ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.folder, color: AppColors.primary),
                          ),
                          title: Text(folder['name'], style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          subtitle: Text('${folder['count']} articles', style: TextStyle(color: Colors.grey.shade500)),
                          trailing: Icon(Icons.chevron_right, color: textColor),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookmarkFolderDetailScreen(
                                  folderId: folder['id'],
                                  folderName: folder['name'],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
