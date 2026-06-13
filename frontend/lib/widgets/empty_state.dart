import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Reusable empty-state widget — tampil di banyak layar (bookmark,
/// history, notifications, search, dst) sehingga punya look & feel konsisten.
///
/// Pemakaian:
/// ```dart
/// EmptyState.noBookmarks(
///   onExplore: () => Navigator.pushReplacementNamed(context, '/explore'),
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final double iconSize;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.iconSize = 64,
  });

  // ---------------------------------------------------------------------------
  // Factory constructors untuk use-case umum
  // ---------------------------------------------------------------------------

  factory EmptyState.noBookmarks({VoidCallback? onExplore}) => EmptyState(
        icon: Icons.bookmark_border,
        title: 'Belum ada bookmark',
        subtitle: 'Tap ikon bookmark di artikel untuk menyimpannya',
        actionLabel: onExplore != null ? 'Jelajahi Berita' : null,
        onAction: onExplore,
      );

  factory EmptyState.noBookmarksSearch() => const EmptyState(
        icon: Icons.search_off,
        title: 'Bookmark tidak ditemukan',
        subtitle: 'Coba kata kunci lain',
      );

  factory EmptyState.noHistory() => const EmptyState(
        icon: Icons.history,
        title: 'Belum ada riwayat',
        subtitle: 'Artikel yang kamu baca akan muncul di sini',
      );

  factory EmptyState.noNotifications() => const EmptyState(
        icon: Icons.notifications_none,
        title: 'Tidak ada notifikasi',
        subtitle: 'Kami akan kabari kamu saat ada berita penting',
      );

  factory EmptyState.noFolders({VoidCallback? onCreate}) => EmptyState(
        icon: Icons.folder_open,
        title: 'Belum ada folder',
        subtitle: 'Buat folder untuk mengelompokkan bookmark',
        actionLabel: onCreate != null ? 'Buat Folder' : null,
        onAction: onCreate,
      );

  factory EmptyState.noSearchResults() => const EmptyState(
        icon: Icons.search_off,
        title: 'Tidak ditemukan',
        subtitle: 'Coba kata kunci lain atau ubah filter',
      );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.hintColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final tint = iconColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon dalam container soft-bg (lingkaran)
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: iconSize * 0.6,
                color: tint.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: mutedColor,
                  height: 1.4,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: tint,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
