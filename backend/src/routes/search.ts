import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { decodeCursor, encodeCursor } from '../lib/cursor'
import { authPlugin } from '../middleware/auth'

interface RawArticle {
  id: string
  externalId: string
  title: string
  originalContent: string | null
  summary: string
  sourceUrl: string | null
  sourceName: string | null
  imageUrl: string | null
  category: string | null
  language: string
  publishedAt: Date | null
  createdAt: Date
  updatedAt: Date
  likesCount: number
}

export const searchRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)

  .get('/search', async ({ query, user, set }) => {
    const q = (query.q as string).trim()
    const limit = Math.min(Number(query.limit) || 10, 50)
    const cursor = query.cursor as string | undefined
    const category = query.category as string | undefined
    const language = query.language as string | undefined

    if (!q) {
      return {
        data: [],
        meta: { hasMore: false, nextCursor: null }
      }
    }

    let decodedCursor = null
    if (cursor) {
      decodedCursor = decodeCursor(cursor)
      if (!decodedCursor) {
        set.status = 400
        return { message: 'Invalid cursor' }
      }
    }

    // Build conditions with parameterized query
    const conditions: string[] = []
    const params: any[] = []
    let p = 1

    // Full-text search using tsvector with ranking
    conditions.push(`"search_vector" @@ plainto_tsquery('simple', $${p})`)
    params.push(q)
    p++

    if (category) {
      conditions.push(`"category" = $${p}`)
      params.push(category)
      p++
    }

    if (language) {
      conditions.push(`"language" = $${p}`)
      params.push(language)
      p++
    }

    if (decodedCursor) {
      conditions.push(`(
        "createdAt" < $${p}
        OR ("createdAt" = $${p} AND "id" < $${p + 1})
      )`)
      params.push(decodedCursor.createdAt, decodedCursor.id)
      p += 2
    }

    const whereClause = conditions.length > 0
      ? `WHERE ${conditions.join(' AND ')}`
      : ''

    // Add ts_rank parameter (reuse $1 since it's the same search query)
    const rankParam = 1
    // Add limit parameter
    params.push(limit + 1)
    const limitParam = p

    // Raw SQL with full-text search and ranking
    const sql = `
      SELECT
        a."id", a."externalId", a."title", a."originalContent", a."summary",
        a."sourceUrl", a."sourceName", a."imageUrl", a."category", a."language",
        a."publishedAt", a."createdAt", a."updatedAt",
        COALESCE(lc.likes_count, 0)::int AS "likesCount",
        ts_rank(a."search_vector", plainto_tsquery('simple', $${rankParam})) AS "rank"
      FROM "Article" a
      LEFT JOIN (
        SELECT "articleId", COUNT(*)::int AS likes_count
        FROM "Like"
        GROUP BY "articleId"
      ) lc ON lc."articleId" = a."id"
      ${whereClause}
      ORDER BY "rank" DESC, a."createdAt" DESC, a."id" DESC
      LIMIT $${limitParam}
    `

    const articles: RawArticle[] = await prisma.$queryRawUnsafe(sql, ...params)

    const hasMore = articles.length > limit
    const dataToReturn = hasMore ? articles.slice(0, limit) : articles

    // Hydrate user likes & bookmarks
    let userLikes = new Set<string>()
    let userBookmarks = new Set<string>()

    if (user?.id && dataToReturn.length > 0) {
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
      likesCount: a.likesCount,
      isLiked: userLikes.has(a.id),
      isBookmarked: userBookmarks.has(a.id)
    }))

    let nextCursor = null
    if (hasMore && dataToReturn.length > 0) {
      const lastItem = dataToReturn[dataToReturn.length - 1]!
      nextCursor = encodeCursor(lastItem.createdAt, lastItem.id)
    }

    return {
      data: formattedData,
      meta: { hasMore, nextCursor }
    }
  }, {
    query: t.Object({
      q: t.String(),
      limit: t.Optional(t.String()),
      cursor: t.Optional(t.String()),
      category: t.Optional(t.String()),
      language: t.Optional(t.String()),
    })
  })
