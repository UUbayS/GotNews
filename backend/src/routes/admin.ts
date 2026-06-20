import { Elysia, t } from 'elysia'
import { authPlugin } from '../middleware/auth'
import { syncNewsJob } from '../jobs/sync-news'
import { bookmarkReminderJob } from '../jobs/bookmark-reminders'
import { prisma } from '../lib/prisma'
import { summarizeArticle } from '../services/summarizer'
import { notifyBreakingArticle, createNotification } from '../services/notifications'

export const adminRoutes = new Elysia({ prefix: '/api/admin' })
  .use(authPlugin)

  // 13. GET /api/admin/stats - Statistics for Admin Dashboard
  .get('/stats', async ({ set }) => {
    try {
      const today = new Date()
      today.setHours(0, 0, 0, 0)

      const [
        totalUsers,
        totalArticles,
        totalLikes,
        totalBookmarks,
        articlesToday,
        activeSources
      ] = await Promise.all([
        prisma.user.count(),
        prisma.article.count(),
        prisma.like.count(),
        prisma.bookmark.count(),
        prisma.article.count({ where: { createdAt: { gte: today } } }),
        prisma.newsSource.count({ where: { isActive: true } })
      ])

      return {
        totalUsers,
        totalArticles,
        totalLikes,
        totalBookmarks,
        articlesToday,
        activeSources
      }
    } catch (e) {
      console.error('Failed to fetch stats:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // Trigger Sync (GET & POST)
  .get('/sync', async () => {
    await syncNewsJob()
    return { success: true, message: 'Sync triggered' }
  }, { requireAdmin: true })

  .post('/sync', async () => {
    await syncNewsJob()
    return { success: true, message: 'Sync triggered' }
  }, { requireAdmin: true })

  // 1. GET /api/admin/users - List all users with roles, registration date, and interaction count
  .get('/users', async ({ set }) => {
    try {
      const users = await prisma.user.findMany({
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          name: true,
          username: true,
          email: true,
          role: true,
          avatarUrl: true,
          createdAt: true,
          isBanned: true,
          bannedAt: true,
          bannedReason: true,
          banExpiresAt: true,
          _count: {
            select: {
              bookmarks: true,
              likes: true
            }
          }
        }
      })
      return { data: users }
    } catch (e) {
      console.error('Failed to list users:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 1b. PUT /api/admin/users/:id/ban - Ban user (with optional duration + email blacklist sync)
  .put('/users/:id/ban', async ({ params, body, set, user }) => {
    try {
      const { id } = params
      const { reason, duration } = body as { reason?: string; duration?: string }

      if (!user || user.id === id) {
        set.status = 400
        return { message: 'Anda tidak dapat mem-ban akun Anda sendiri' }
      }

      const target = await prisma.user.findUnique({ where: { id } })
      if (!target) {
        set.status = 404
        return { message: 'User tidak ditemukan' }
      }

      if (target.role === 'admin') {
        set.status = 400
        return { message: 'Tidak dapat mem-ban admin. Turunkan role-nya terlebih dahulu.' }
      }

      if (target.isBanned) {
        set.status = 400
        return { message: 'User sudah di-ban' }
      }

      let banExpiresAt: Date | null = null
      if (duration && duration !== 'permanent') {
        const days = parseInt(duration.replace('d', ''), 10)
        if (isNaN(days) || days <= 0) {
          set.status = 400
          return { message: 'Durasi ban tidak valid. Gunakan 1d/7d/30d atau permanent.' }
        }
        banExpiresAt = new Date(Date.now() + days * 24 * 60 * 60 * 1000)
      }

      const now = new Date()

      const updated = await prisma.$transaction(async (tx) => {
        const u = await tx.user.update({
          where: { id },
          data: {
            isBanned: true,
            bannedAt: now,
            bannedReason: reason || null,
            bannedBy: user.id,
            banExpiresAt,
          },
          select: {
            id: true, email: true, isBanned: true, bannedAt: true,
            bannedReason: true, banExpiresAt: true
          }
        })

        await tx.bannedEmail.upsert({
          where: { email: target.email },
          update: {
            reason: reason || null,
            bannedBy: user.id,
            bannedAt: now,
            expiresAt: banExpiresAt,
          },
          create: {
            email: target.email,
            reason: reason || null,
            bannedBy: user.id,
            bannedAt: now,
            expiresAt: banExpiresAt,
          }
        })

        return u
      })

      return {
        success: true,
        message: banExpiresAt
          ? `User di-ban hingga ${banExpiresAt.toISOString()}`
          : 'User di-ban secara permanen',
        data: updated
      }
    } catch (e) {
      console.error('Failed to ban user:', e)
      set.status = 500
      return { message: 'Gagal mem-ban user' }
    }
  }, {
    body: t.Object({
      reason: t.Optional(t.String()),
      duration: t.Optional(t.Union([
        t.Literal('1d'),
        t.Literal('7d'),
        t.Literal('30d'),
        t.Literal('permanent'),
      ]))
    }),
    requireAdmin: true
  })

  // 1c. PUT /api/admin/users/:id/unban - Unban user + remove from email blacklist
  .put('/users/:id/unban', async ({ params, set }) => {
    try {
      const { id } = params

      const target = await prisma.user.findUnique({ where: { id } })
      if (!target) {
        set.status = 404
        return { message: 'User tidak ditemukan' }
      }

      if (!target.isBanned) {
        set.status = 400
        return { message: 'User tidak sedang di-ban' }
      }

      await prisma.$transaction(async (tx) => {
        await tx.user.update({
          where: { id },
          data: {
            isBanned: false,
            bannedAt: null,
            bannedReason: null,
            bannedBy: null,
            banExpiresAt: null,
          }
        })

        await tx.bannedEmail.deleteMany({
          where: { email: target.email }
        })
      })

      return { success: true, message: 'User berhasil di-unban' }
    } catch (e) {
      console.error('Failed to unban user:', e)
      set.status = 500
      return { message: 'Gagal meng-unban user' }
    }
  }, {
    requireAdmin: true
  })

  // 2. PUT /api/admin/users/:id/promote - Promote user to admin
  .put('/users/:id/promote', async ({ params, set }) => {
    try {
      const { id } = params
      const userToPromote = await prisma.user.findUnique({ where: { id } })
      if (!userToPromote) {
        set.status = 404
        return { message: 'User not found' }
      }

      const updated = await prisma.user.update({
        where: { id },
        data: { role: 'admin' },
        select: { id: true, email: true, role: true }
      })

      return { success: true, message: 'User promoted to admin successfully', data: updated }
    } catch (e) {
      console.error('Failed to promote user:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 3. PUT /api/admin/users/:id/demote - Demote admin to user (checks if it's the last admin)
  .put('/users/:id/demote', async ({ params, set, user }) => {
    try {
      const { id } = params
      const userToDemote = await prisma.user.findUnique({ where: { id } })
      if (!userToDemote) {
        set.status = 404
        return { message: 'User not found' }
      }

      if (userToDemote.role !== 'admin') {
        set.status = 400
        return { message: 'User is not an admin' }
      }

      // Check if this is the only admin
      const adminCount = await prisma.user.count({ where: { role: 'admin' } })
      if (adminCount <= 1) {
        set.status = 400
        return { message: 'Cannot demote the only administrator in the system' }
      }

      const updated = await prisma.user.update({
        where: { id },
        data: { role: 'user' },
        select: { id: true, email: true, role: true }
      })

      return { success: true, message: 'Admin demoted to user successfully', data: updated }
    } catch (e) {
      console.error('Failed to demote admin:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 4. DELETE /api/admin/users/:id - Delete user (cannot delete self, cannot delete last admin)
  .delete('/users/:id', async ({ params, set, user }) => {
    try {
      const { id } = params
      
      if (!user || user.id === id) {
        set.status = 400
        return { message: 'You cannot delete your own account' }
      }

      const userToDelete = await prisma.user.findUnique({ where: { id } })
      if (!userToDelete) {
        set.status = 404
        return { message: 'User not found' }
      }

      if (userToDelete.role === 'admin') {
        const adminCount = await prisma.user.count({ where: { role: 'admin' } })
        if (adminCount <= 1) {
          set.status = 400
          return { message: 'Cannot delete the only administrator in the system' }
        }
      }

      await prisma.user.delete({ where: { id } })
      return { success: true, message: 'User deleted successfully' }
    } catch (e) {
      console.error('Failed to delete user:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 5. GET /api/admin/articles - List articles with pagination & filter
  .get('/articles', async ({ query, set }) => {
    try {
      const limit = Math.min(Number(query.limit) || 20, 100)
      const page = Math.max(Number(query.page) || 1, 1)
      const offset = (page - 1) * limit
      const category = query.category as string | undefined
      const sourceName = query.source as string | undefined
      const search = query.search as string | undefined

      const where: any = {}
      if (category && category !== 'All' && category !== 'all') {
        where.category = category.toLowerCase()
      }
      if (sourceName) {
        where.sourceName = sourceName
      }
      if (search && search.trim() !== '') {
        where.title = { contains: search, mode: 'insensitive' }
      }

      const [articles, total] = await Promise.all([
        prisma.article.findMany({
          where,
          take: limit,
          skip: offset,
          orderBy: { createdAt: 'desc' },
          include: {
            _count: {
              select: { likes: true, bookmarks: true }
            }
          }
        }),
        prisma.article.count({ where })
      ])

      return {
        data: articles.map(a => ({
          ...a,
          likesCount: a._count.likes,
          bookmarksCount: a._count.bookmarks
        })),
        meta: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit)
        }
      }
    } catch (e) {
      console.error('Failed to list articles:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    query: t.Object({
      limit: t.Optional(t.String()),
      page: t.Optional(t.String()),
      category: t.Optional(t.String()),
      source: t.Optional(t.String()),
      search: t.Optional(t.String())
    }),
    requireAdmin: true
  })

  // 6. PUT /api/admin/articles/:id - Edit article (title, summary, category, sourceName, originalContent)
  .put('/articles/:id', async ({ params, body, set }) => {
    try {
      const { id } = params
      const { title, summary, category, sourceName, originalContent } = body

      const article = await prisma.article.findUnique({ where: { id } })
      if (!article) {
        set.status = 404
        return { message: 'Article not found' }
      }

      const updated = await prisma.article.update({
        where: { id },
        data: {
          title,
          summary,
          category: category.toLowerCase(),
          sourceName,
          originalContent: originalContent || null
        }
      })

      return { success: true, message: 'Article updated successfully', data: updated }
    } catch (e) {
      console.error('Failed to update article:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    body: t.Object({
      title: t.String({ minLength: 1 }),
      summary: t.String({ minLength: 1 }),
      category: t.String({ minLength: 1 }),
      sourceName: t.String({ minLength: 1 }),
      originalContent: t.Optional(t.String())
    }),
    requireAdmin: true
  })

  // 7. DELETE /api/admin/articles/:id - Delete article
  .delete('/articles/:id', async ({ params, set }) => {
    try {
      const { id } = params
      const article = await prisma.article.findUnique({ where: { id } })
      if (!article) {
        set.status = 404
        return { message: 'Article not found' }
      }

      await prisma.article.delete({ where: { id } })
      return { success: true, message: 'Article deleted successfully' }
    } catch (e) {
      console.error('Failed to delete article:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 8. POST /api/admin/articles/bulk-delete - Bulk delete articles
  .post('/articles/bulk-delete', async ({ body, set }) => {
    try {
      const { ids, sourceName } = body

      if ((!ids || ids.length === 0) && !sourceName) {
        set.status = 400
        return { message: 'Either ids or sourceName must be provided' }
      }

      const where: any = {}
      if (ids && ids.length > 0) {
        where.id = { in: ids }
      } else if (sourceName) {
        where.sourceName = sourceName
      }

      const deleted = await prisma.article.deleteMany({ where })
      return { success: true, message: `Successfully deleted ${deleted.count} articles` }
    } catch (e) {
      console.error('Failed to bulk delete articles:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    body: t.Object({
      ids: t.Optional(t.Array(t.String())),
      sourceName: t.Optional(t.String())
    }),
    requireAdmin: true
  })

  // 9. GET /api/admin/sources - List news sources
  .get('/sources', async ({ set }) => {
    try {
      const sources = await prisma.newsSource.findMany({
        orderBy: { name: 'asc' }
      })
      return { data: sources }
    } catch (e) {
      console.error('Failed to list sources:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 10. POST /api/admin/sources - Add news source
  .post('/sources', async ({ body, set }) => {
    try {
      const { name, sourceId, language, isActive } = body

      const existing = await prisma.newsSource.findUnique({ where: { sourceId } })
      if (existing) {
        set.status = 400
        return { message: 'News source with this ID already exists' }
      }

      const source = await prisma.newsSource.create({
        data: {
          name,
          sourceId,
          language,
          isActive: isActive ?? true
        }
      })

      return { success: true, message: 'Source added successfully', data: source }
    } catch (e) {
      console.error('Failed to add source:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    body: t.Object({
      name: t.String({ minLength: 1 }),
      sourceId: t.String({ minLength: 1 }),
      language: t.String({ minLength: 2 }),
      isActive: t.Optional(t.Boolean())
    }),
    requireAdmin: true
  })

  // 11. PUT /api/admin/sources/:id - Edit source (name, active status)
  .put('/sources/:id', async ({ params, body, set }) => {
    try {
      const { id } = params
      const { name, isActive, language } = body

      const source = await prisma.newsSource.findUnique({ where: { id } })
      if (!source) {
        set.status = 404
        return { message: 'News source not found' }
      }

      const updated = await prisma.newsSource.update({
        where: { id },
        data: {
          name,
          isActive,
          language
        }
      })

      return { success: true, message: 'News source updated successfully', data: updated }
    } catch (e) {
      console.error('Failed to update source:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    body: t.Object({
      name: t.Optional(t.String()),
      isActive: t.Optional(t.Boolean()),
      language: t.Optional(t.String())
    }),
    requireAdmin: true
  })

  // 12. DELETE /api/admin/sources/:id - Delete news source
  .delete('/sources/:id', async ({ params, set }) => {
    try {
      const { id } = params
      const source = await prisma.newsSource.findUnique({ where: { id } })
      if (!source) {
        set.status = 404
        return { message: 'News source not found' }
      }

      await prisma.newsSource.delete({ where: { id } })
      return { success: true, message: 'News source deleted successfully' }
    } catch (e) {
      console.error('Failed to delete source:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    requireAdmin: true
  })

  // 14. POST /api/admin/articles/:id/sync-ai-summary - Regenerate AI summary
  .post('/articles/:id/sync-ai-summary', async ({ params, set }) => {
    try {
      const { id } = params
      const article = await prisma.article.findUnique({ where: { id } })
      if (!article) {
        set.status = 404
        return { message: 'Article not found' }
      }

      const content = article.originalContent || article.summary || article.title
      const summary = await summarizeArticle(content, article.language || 'en')
      
      if (!summary || summary.length < 10) {
        set.status = 500
        return { message: 'AI failed to generate summary' }
      }

      const now = new Date()
      await prisma.article.update({
        where: { id },
        data: {
          aiSummary: summary,
          aiSummaryAt: now
        }
      })

      return {
        success: true,
        message: 'AI Summary regenerated successfully',
        summary,
        generatedAt: now
      }
    } catch (e) {
      console.error('Failed to regenerate AI summary:', e)
      set.status = 500
      return { message: 'AI summarization failed' }
    }
  }, {
    requireAdmin: true
  })

  // 15. PUT /api/admin/articles/:id/breaking - Toggle breaking-news flag and push to all users
  .put('/articles/:id/breaking', async ({ params, body, set }) => {
    try {
      const { id } = params
      const { isBreaking } = body
      const article = await prisma.article.findUnique({ where: { id } })
      if (!article) {
        set.status = 404
        return { message: 'Article not found' }
      }

      const updated = await prisma.article.update({
        where: { id },
        data: {
          isBreaking,
          breakingAt: isBreaking ? new Date() : null
        }
      })

      if (isBreaking) {
        await notifyBreakingArticle(article.id, article.title)
      }

      return {
        success: true,
        message: isBreaking ? 'Marked as breaking news' : 'Breaking flag removed',
        data: updated
      }
    } catch (e) {
      console.error('Failed to toggle breaking:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    body: t.Object({
      isBreaking: t.Boolean()
    }),
    requireAdmin: true
  })

  // 16. POST /api/admin/notifications/test - Trigger test notifications (admin self) for manual QA
  .post('/notifications/test', async ({ body, set, user }) => {
    try {
      const { type, articleId, userId } = body
      const targetUserId = userId ?? user?.id
      if (!targetUserId) {
        set.status = 401
        return { message: 'Unauthorized' }
      }

      if (type === 'breaking') {
        const article = articleId
          ? await prisma.article.findUnique({ where: { id: articleId } })
          : await prisma.article.findFirst({ orderBy: { createdAt: 'desc' } })

        if (!article) {
          set.status = 404
          return { message: 'No article available. Sync news first or pass articleId.' }
        }

        await notifyBreakingArticle(article.id, article.title, userId)
        return {
          success: true,
          message: userId
            ? `Breaking push sent to user ${targetUserId}: "${article.title}"`
            : `Breaking push queued to all users: "${article.title}"`,
          articleId: article.id,
          userId: targetUserId
        }
      }

      if (type === 'reminder' || type === 'bookmark') {
        await createNotification(
          targetUserId,
          'Belum Selesai Dibaca',
          userId
            ? 'Ini adalah notifikasi percobaan reminder yang dikirim admin ke akun Anda.'
            : 'Ini adalah notifikasi percobaan untuk fitur pengingat bookmark.',
          'reminder'
        )
        return { success: true, message: `Reminder sent to user ${targetUserId}.` }
      }

      if (type === 'run-job') {
        const result = await bookmarkReminderJob()
        return { success: true, message: `Bookmark job executed. Sent: ${result.sent}` }
      }

      set.status = 400
      return { message: `Unknown type "${type}". Use: breaking | reminder | run-job.` }
    } catch (e) {
      console.error('Failed to send test notification:', e)
      set.status = 500
      return { message: 'Internal server error' }
    }
  }, {
    body: t.Object({
      type: t.String(),
      articleId: t.Optional(t.String()),
      userId: t.Optional(t.String())
    }),
    requireAdmin: true
  })
