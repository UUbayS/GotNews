import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { authPlugin } from '../middleware/auth'
import { decodeCursor, encodeCursor } from '../lib/cursor'

export const interactionRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  
  // BOOKMARK TOGGLE (POST / DELETE)
  .post('/articles/:id/bookmark', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const articleId = params.id
    const article = await prisma.article.findUnique({ where: { id: articleId } })
    if (!article) {
      set.status = 404
      return { message: 'Article not found' }
    }

    const existing = await prisma.bookmark.findUnique({
      where: { userId_articleId: { userId: user.id, articleId } }
    })

    if (existing) {
      return { success: true, message: 'Already bookmarked' }
    }

    await prisma.bookmark.create({
      data: { userId: user.id, articleId }
    })

    return { success: true, message: 'Bookmarked' }
  }, { requireAuth: true })

  .delete('/articles/:id/bookmark', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      await prisma.bookmark.delete({
        where: {
          userId_articleId: {
            userId: user.id,
            articleId: params.id
          }
        }
      })
      return { success: true, message: 'Bookmark removed' }
    } catch (e) {
      console.error('[Interaction] Bookmark DELETE error:', e)
      set.status = 400
      return { message: 'Not bookmarked or error' }
    }
  }, { requireAuth: true })

  // GET BOOKMARKS (paginated)
  .get('/bookmarks', async ({ query, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const limit = Math.min(Number(query.limit) || 50, 50)
    const cursor = query.cursor as string | undefined

    let decodedCursor: { createdAt: Date; id: string } | null = null
    if (cursor) {
      decodedCursor = decodeCursor(cursor)
      if (!decodedCursor) {
        set.status = 400
        return { message: 'Invalid cursor' }
      }
    }

    const whereClause: any = { userId: user.id }
    if (decodedCursor) {
      whereClause.createdAt = { lt: decodedCursor.createdAt }
    }

    const bookmarks = await prisma.bookmark.findMany({
      where: whereClause,
      include: {
        article: {
          include: {
            _count: { select: { likes: true } }
          }
        }
      },
      orderBy: { createdAt: 'desc' },
      take: limit + 1
    })

    const hasMore = bookmarks.length > limit
    const dataToReturn = hasMore ? bookmarks.slice(0, limit) : bookmarks

    const articleIds = dataToReturn.map(b => b.articleId)
    const userLikes = await prisma.like.findMany({
      where: { userId: user.id, articleId: { in: articleIds } }
    })
    const likedSet = new Set(userLikes.map(l => l.articleId))

    let nextCursor = null
    if (hasMore && dataToReturn.length > 0) {
      const lastItem = dataToReturn[dataToReturn.length - 1]!
      nextCursor = encodeCursor(lastItem.createdAt, lastItem.id)
    }

    return {
      data: dataToReturn.map(b => ({
        id: b.article.id,
        title: b.article.title,
        summary: b.article.summary,
        originalContent: b.article.originalContent,
        imageUrl: b.article.imageUrl,
        sourceName: b.article.sourceName,
        category: b.article.category,
        language: b.article.language,
        publishedAt: b.article.publishedAt,
        likesCount: b.article._count.likes,
        isLiked: likedSet.has(b.article.id),
        isBookmarked: true
      })),
      meta: { hasMore, nextCursor }
    }
  }, {
    query: t.Object({
      limit: t.Optional(t.String()),
      cursor: t.Optional(t.String())
    }),
    requireAuth: true
  })

  // LIKE TOGGLE (POST / DELETE)
  .post('/articles/:id/like', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const existing = await prisma.like.findUnique({
      where: { userId_articleId: { userId: user.id, articleId: params.id } }
    })

    if (existing) {
      return { success: true, message: 'Already liked' }
    }

    await prisma.like.create({
      data: { userId: user.id, articleId: params.id }
    })

    return { success: true, message: 'Liked' }
  }, { requireAuth: true })

  .delete('/articles/:id/like', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      await prisma.like.delete({
        where: {
          userId_articleId: {
            userId: user.id,
            articleId: params.id
          }
        }
      })
      return { success: true, message: 'Like removed' }
    } catch (e) {
      set.status = 400
      return { message: 'Not liked or error' }
    }
  }, { requireAuth: true })

  // READING HISTORY
  .post('/reading-history', async ({ body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const { articleId, readProgress, durationSec } = body

    const article = await prisma.article.findUnique({ where: { id: articleId } })
    if (!article) {
      set.status = 404
      return { message: 'Article not found' }
    }

    try {
      const history = await prisma.readingHistory.upsert({
        where: {
          userId_articleId: { userId: user.id, articleId }
        },
        update: {
          readAt: new Date(),
          readProgress: readProgress ?? 0,
          durationSec: { increment: durationSec ?? 0 },
        },
        create: {
          userId: user.id,
          articleId,
          readProgress: readProgress ?? 0,
          durationSec: durationSec ?? 0,
        }
      })
      return { success: true, history }
    } catch (e) {
      console.error('[Interaction] ReadingHistory POST error:', e)
      set.status = 400
      return { message: 'Failed to record reading history' }
    }
  }, {
    body: t.Object({
      articleId: t.String(),
      readProgress: t.Optional(t.Number()),
      durationSec: t.Optional(t.Number()),
    }),
    requireAuth: true
  })

  .get('/reading-history', async ({ query, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const limit = Math.min(Number(query.limit) || 20, 50)

    const history = await prisma.readingHistory.findMany({
      where: { userId: user.id },
      include: {
        article: {
          include: {
            _count: { select: { likes: true } }
          }
        }
      },
      orderBy: { readAt: 'desc' },
      take: limit,
    })

    const articleIds = history.map(h => h.articleId)
    const userLikes = await prisma.like.findMany({
      where: { userId: user.id, articleId: { in: articleIds } }
    })
    const userBookmarks = await prisma.bookmark.findMany({
      where: { userId: user.id, articleId: { in: articleIds } }
    })
    const likedSet = new Set(userLikes.map(l => l.articleId))
    const bookmarkedSet = new Set(userBookmarks.map(b => b.articleId))

    return {
      data: history.map(h => ({
        id: h.article.id,
        title: h.article.title,
        summary: h.article.summary,
        imageUrl: h.article.imageUrl,
        sourceName: h.article.sourceName,
        category: h.article.category,
        publishedAt: h.article.publishedAt,
        likesCount: h.article._count.likes,
        isLiked: likedSet.has(h.article.id),
        isBookmarked: bookmarkedSet.has(h.article.id),
        readProgress: h.readProgress,
        readAt: h.readAt,
        durationSec: h.durationSec,
      })),
    }
  }, {
    query: t.Object({
      limit: t.Optional(t.String()),
    }),
    requireAuth: true
  })
