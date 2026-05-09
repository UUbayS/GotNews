import { Elysia, t } from 'elysia'
import { authPlugin } from '../middleware/auth'
import { askAIAboutArticle } from '../services/ai-chat'
import { prisma } from '../lib/prisma'

export const aiRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  
  /**
   * POST /api/chat
   * Protected route for logged in users to ask questions about an article.
   */
  .post('/chat', async ({ body, user, set }) => {
    const { articleId, question } = body
    
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized. Please login to use AI features.' }
    }
    
    const article = await prisma.article.findUnique({ where: { id: articleId } })
    
    if (!article) {
      set.status = 404
      return { message: 'Article not found' }
    }
    
    const context = article.originalContent || article.summary || article.title
    
    try {
      const answer = await askAIAboutArticle(context, question)
      return { answer }
    } catch (e) {
      console.error('AI Chat Error:', e)
      set.status = 500
      return { message: 'AI failed to respond' }
    }
  }, {
    body: t.Object({
      articleId: t.String(),
      question: t.String()
    }),
    requireAuth: true
  })
