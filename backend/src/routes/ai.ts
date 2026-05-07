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
  .post('/chat', async ({ body, user, error }) => {
    const { articleId, question } = body
    
    // Check if user is authenticated
    if (!user) return error(401, { message: 'Unauthorized. Please login to use AI features.' })
    
    // 1. Fetch article from DB to get context
    const article = await prisma.article.findUnique({
      where: { id: articleId }
    })
    
    if (!article) return error(404, { message: 'Article not found' })
    
    // 2. Prepare context (prefer original content if available, else summary)
    const context = article.originalContent || article.summary || article.title
    
    // 3. Ask AI
    try {
      const answer = await askAIAboutArticle(context, question)
      return { answer }
    } catch (e) {
      console.error('AI Chat Error:', e)
      return error(500, { message: 'AI failed to respond' })
    }
  }, {
    body: t.Object({
      articleId: t.String(),
      question: t.String()
    }),
    requireAuth: true
  })
