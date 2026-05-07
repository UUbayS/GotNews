import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { authPlugin } from '../middleware/auth'

export const interactionRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  
  // BOOKMARK TOGGLE (POST / DELETE)
  .post('/articles/:id/bookmark', async ({ params, user, error }) => {
    if (!user) return error(401, { message: 'Unauthorized' })
    
    const articleId = params.id
    const article = await prisma.article.findUnique({ where: { id: articleId } })
    if (!article) return error(404, { message: 'Article not found' })

    try {
      await prisma.bookmark.create({
        data: {
          userId: user.id,
          articleId
        }
      })
      return { success: true, message: 'Bookmarked' }
    } catch (e) {
      return error(400, { message: 'Already bookmarked or error' })
    }
  }, { requireAuth: true })
  
  .delete('/articles/:id/bookmark', async ({ params, user, error }) => {
    if (!user) return error(401, { message: 'Unauthorized' })
    
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
      return error(400, { message: 'Not bookmarked or error' })
    }
  }, { requireAuth: true })

  // GET ALL BOOKMARKS
  .get('/bookmarks', async ({ user, error }) => {
    if (!user) return error(401, { message: 'Unauthorized' })

    const bookmarks = await prisma.bookmark.findMany({
      where: { userId: user.id },
      include: {
        article: true
      },
      orderBy: { createdAt: 'desc' }
    })

    return {
      data: bookmarks.map(b => b.article)
    }
  }, { requireAuth: true })

  // LIKE TOGGLE (POST / DELETE)
  .post('/articles/:id/like', async ({ params, user, error }) => {
    if (!user) return error(401, { message: 'Unauthorized' })
    
    try {
      await prisma.like.create({
        data: {
          userId: user.id,
          articleId: params.id
        }
      })
      return { success: true, message: 'Liked' }
    } catch (e) {
      return error(400, { message: 'Already liked or error' })
    }
  }, { requireAuth: true })

  .delete('/articles/:id/like', async ({ params, user, error }) => {
    if (!user) return error(401, { message: 'Unauthorized' })
    
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
      return error(400, { message: 'Not liked or error' })
    }
  }, { requireAuth: true })
