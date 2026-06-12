import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { Prisma } from '@prisma/client'
import { decodeCursor, encodeCursor } from '../lib/cursor'
import { authPlugin } from '../middleware/auth'

export const feedRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  
  .get('/feed', async ({ query, user, set }) => {
    const limit = Math.min(Number(query.limit) || 10, 50)
    const cursor = query.cursor as string | undefined
    const category = query.category as string | undefined
    const language = query.language as string | undefined
    const personalized = query.personalized === 'true'

    let decodedCursor = null;
    if (cursor) {
      decodedCursor = decodeCursor(cursor);
      if (!decodedCursor) {
        set.status = 400
        return { message: 'Invalid cursor' }
      }
    }

    // Get user's preferred categories from bookmarks
    let topCategories: string[] = []
    if (personalized && user?.id && !decodedCursor) {
      const userBookmarks = await prisma.bookmark.findMany({
        where: { userId: user.id },
        include: { article: { select: { category: true } } },
        take: 50
      })
      topCategories = [...new Set(
        userBookmarks.map(b => b.article.category).filter((c): c is string => c !== null)
      )]
    }

    // Build WHERE clause
    const whereClause: Prisma.ArticleWhereInput = {}
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

    const fetchLimit = topCategories.length > 0 ? limit * 3 + 1 : limit + 1

    // Fetch articles
    const articles = await prisma.article.findMany({
      where: whereClause,
      take: fetchLimit,
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

    // Boost matching categories for personalized feed
    let sortedArticles = articles
    if (topCategories.length > 0) {
      sortedArticles = [...articles].sort((a, b) => {
        const aMatch = a.category && topCategories.includes(a.category) ? 1 : 0
        const bMatch = b.category && topCategories.includes(b.category) ? 1 : 0
        if (aMatch !== bMatch) return bMatch - aMatch
        return b.createdAt.getTime() - a.createdAt.getTime()
      })
    }

    const hasMore = sortedArticles.length > limit
    const dataToReturn = hasMore ? sortedArticles.slice(0, limit) : sortedArticles

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
      sourceUrl: a.sourceUrl,
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
      const lastItem = dataToReturn[dataToReturn.length - 1]!
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
      language: t.Optional(t.String()),
      personalized: t.Optional(t.String()),
    })
  })

  // GET single article by ID
  .get('/articles/:id', async ({ params, user, set }) => {
    const article = await prisma.article.findUnique({
      where: { id: params.id },
      include: {
        _count: { select: { likes: true, bookmarks: true } }
      }
    })

    if (!article) {
      set.status = 404
      return { message: 'Article not found' }
    }

    let isLiked = false
    let isBookmarked = false

    if (user?.id) {
      const [like, bookmark] = await Promise.all([
        prisma.like.findUnique({
          where: { userId_articleId: { userId: user.id, articleId: article.id } }
        }),
        prisma.bookmark.findUnique({
          where: { userId_articleId: { userId: user.id, articleId: article.id } }
        })
      ])
      isLiked = !!like
      isBookmarked = !!bookmark
    }

    return {
      id: article.id,
      title: article.title,
      summary: article.summary,
      originalContent: article.originalContent,
      imageUrl: article.imageUrl,
      sourceUrl: article.sourceUrl,
      sourceName: article.sourceName,
      category: article.category,
      language: article.language,
      publishedAt: article.publishedAt,
      createdAt: article.createdAt,
      likesCount: article._count.likes,
      bookmarksCount: article._count.bookmarks,
      isLiked,
      isBookmarked
    }
  })

  // GET categories with article counts
  .get('/categories', async () => {
    const categories = await prisma.article.groupBy({
      by: ['category'],
      _count: { id: true },
      where: { category: { not: null } },
      orderBy: { _count: { id: 'desc' } }
    })

    return {
      data: categories.map(c => ({
        name: c.category,
        count: c._count.id
      }))
    }
  })

  // GET trending articles (top liked in last 24 hours)
  .get('/trending', async ({ query, user }) => {
    const limit = Math.min(Number(query.limit) || 10, 30)
    const category = query.category as string | undefined
    const language = query.language as string | undefined

    const likes = await prisma.like.groupBy({
      by: ['articleId'],
      _count: { id: true },
      where: {
        createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
        article: {
          ...(category ? { category } : {}),
          ...(language ? { language } : {}),
        }
      },
      orderBy: { _count: { id: 'desc' } },
      take: limit,
    })

    const articleIds = likes.map(l => l.articleId)

    if (articleIds.length === 0) {
      return { data: [], meta: { timeframe: '24h' } }
    }

    const articles = await prisma.article.findMany({
      where: { id: { in: articleIds } },
      include: { _count: { select: { likes: true } } },
    })

    const articleMap = new Map(articles.map(a => [a.id, a]))
    const sorted = articleIds
      .map(id => articleMap.get(id)!)
      .filter(Boolean)

    let userLikes = new Set<string>()
    let userBookmarks = new Set<string>()

    if (user?.id) {
      const [userLikesData, userBookmarksData] = await Promise.all([
        prisma.like.findMany({ where: { userId: user.id, articleId: { in: articleIds } } }),
        prisma.bookmark.findMany({ where: { userId: user.id, articleId: { in: articleIds } } }),
      ])
      userLikesData.forEach(l => userLikes.add(l.articleId))
      userBookmarksData.forEach(b => userBookmarks.add(b.articleId))
    }

    return {
      data: sorted.map(a => ({
        id: a.id,
        title: a.title,
        summary: a.summary,
        originalContent: a.originalContent,
        imageUrl: a.imageUrl,
        sourceUrl: a.sourceUrl,
        sourceName: a.sourceName,
        category: a.category,
        language: a.language,
        publishedAt: a.publishedAt,
        likesCount: a._count.likes,
        isLiked: userLikes.has(a.id),
        isBookmarked: userBookmarks.has(a.id),
        trendingScore: likes.find(l => l.articleId === a.id)?._count.id ?? 0,
      })),
      meta: { timeframe: '24h' }
    }
  }, {
    query: t.Object({
      limit: t.Optional(t.String()),
      category: t.Optional(t.String()),
      language: t.Optional(t.String()),
    })
  })