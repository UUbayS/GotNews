import { Elysia } from 'elysia'
import { prisma } from '../lib/prisma'
import { authPlugin } from '../middleware/auth'

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

  // GET ALL BOOKMARKS
  .get('/bookmarks', async ({ user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const bookmarks = await prisma.bookmark.findMany({
      where: { userId: user.id },
      include: {
        article: {
          include: {
            _count: { select: { likes: true } }
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    })

    const articleIds = bookmarks.map(b => b.articleId)
    const userLikes = await prisma.like.findMany({
      where: { userId: user.id, articleId: { in: articleIds } }
    })
    const likedSet = new Set(userLikes.map(l => l.articleId))

    return {
      data: bookmarks.map(b => ({
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
      }))
    }
  }, { requireAuth: true })

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
