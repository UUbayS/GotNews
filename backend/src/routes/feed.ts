import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { decodeCursor, encodeCursor } from '../lib/cursor'
import { authPlugin } from '../middleware/auth'

export const feedRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  
  .get('/feed', async ({ query, user, error }) => {
    const limit = Math.min(Number(query.limit) || 10, 50)
    const cursor = query.cursor as string | undefined
    const category = query.category as string | undefined
    const language = query.language as string | undefined

    let decodedCursor = null;
    if (cursor) {
      decodedCursor = decodeCursor(cursor);
      if (!decodedCursor) {
        return error(400, { message: 'Invalid cursor' })
      }
    }

    // Build WHERE clause
    const whereClause: any = {}
    if (category) whereClause.category = category
    if (language) whereClause.language = language

    if (decodedCursor) {
      whereClause.OR = [
        {
          createdAt: { lt: decodedCursor.createdAt }
        },
        {
          createdAt: decodedCursor.createdAt,
          id: { lt: decodedCursor.id }
        }
      ]
    }

    // Fetch limit + 1 to check if there is a next page
    const articles = await prisma.article.findMany({
      where: whereClause,
      take: limit + 1,
      orderBy: [
        { createdAt: 'desc' },
        { id: 'desc' }
      ],
      include: {
        _count: {
          select: { likes: true }
        }
      }
    })

    const hasMore = articles.length > limit
    const dataToReturn = hasMore ? articles.slice(0, limit) : articles

    // If user is logged in, fetch their likes/bookmarks for these articles
    let userLikes = new Set<string>()
    let userBookmarks = new Set<string>()

    if (user?.id) {
      const articleIds = dataToReturn.map(a => a.id)
      
      const [likes, bookmarks] = await Promise.all([
        prisma.like.findMany({
          where: { userId: user.id, articleId: { in: articleIds } }
        }),
        prisma.bookmark.findMany({
          where: { userId: user.id, articleId: { in: articleIds } }
        })
      ])

      likes.forEach(l => userLikes.add(l.articleId))
      bookmarks.forEach(b => userBookmarks.add(b.articleId))
    }

    // Format response
    const formattedData = dataToReturn.map(a => ({
      id: a.id,
      title: a.title,
      summary: a.summary,
      originalContent: a.originalContent,
      imageUrl: a.imageUrl,
      sourceName: a.sourceName,
      category: a.category,
      language: a.language,
      publishedAt: a.publishedAt,
      likesCount: a._count.likes,
      isLiked: userLikes.has(a.id),
      isBookmarked: userBookmarks.has(a.id)
    }))

    // Generate next cursor
    let nextCursor = null
    if (hasMore && dataToReturn.length > 0) {
      const lastItem = dataToReturn[dataToReturn.length - 1]
      nextCursor = encodeCursor(lastItem.createdAt, lastItem.id)
    }

    return {
      data: formattedData,
      meta: {
        hasMore,
        nextCursor
      }
    }
  }, {
    query: t.Object({
      limit: t.Optional(t.String()),
      cursor: t.Optional(t.String()),
      category: t.Optional(t.String()),
      language: t.Optional(t.String())
    })
  })
