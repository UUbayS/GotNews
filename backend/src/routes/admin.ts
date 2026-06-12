import { Elysia, t } from 'elysia'
import { authPlugin } from '../middleware/auth'
import { syncNewsJob } from '../jobs/sync-news'
import { prisma } from '../lib/prisma'
import { summarizeArticle } from '../services/summarizer'

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
