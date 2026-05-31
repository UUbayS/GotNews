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

    try {
      await prisma.bookmark.create({
        data: { userId: user.id, articleId }
      })
      return { success: true, message: 'Bookmarked' }
    } catch (e) {
      console.error('[Interaction] Bookmark POST error:', e)
      set.status = 400
      return { message: 'Already bookmarked or error' }
    }
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

    const limit = Math.min(Number(query.limit) || 10, 50)
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

    try {
      await prisma.like.create({
        data: { userId: user.id, articleId: params.id }
      })
      return { success: true, message: 'Liked' }
    } catch (e) {
      set.status = 400
      return { message: 'Already liked or error' }
    }
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
