import { Elysia, t } from 'elysia'
import { authPlugin } from '../middleware/auth'
import { askAIAboutArticle } from '../services/ai-chat'
import { summarizeArticle } from '../services/summarizer'
import { prisma } from '../lib/prisma'
import { rateLimit } from '../lib/rate-limit'

export const aiRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)
  .use(rateLimit('ai', 20, 60000))
  
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

  /**
   * POST /api/articles/:id/summarize
   * Protected route — generates AI summary on-demand for a specific article.
   * Uses cached aiSummary field. Pass ?force=true to regenerate.
   */
  .post('/articles/:id/summarize', async ({ params, user, query, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized. Please login to use AI features.' }
    }

    const article = await prisma.article.findUnique({ where: { id: params.id } })

    if (!article) {
      set.status = 404
      return { message: 'Article not found' }
    }

    const force = query.force === 'true'

    if (!force && article.aiSummary) {
      return {
        summary: article.aiSummary,
        cached: true,
        generatedAt: article.aiSummaryAt,
      }
    }

    const content = article.originalContent || article.summary || article.title

    try {
      const summary = await summarizeArticle(content, article.language || 'en')
      if (!summary || summary.length < 10) {
        set.status = 500
        return { message: 'AI failed to generate summary' }
      }

      const now = new Date()
      await prisma.article.update({
        where: { id: params.id },
        data: { aiSummary: summary, aiSummaryAt: now }
      })

      return {
        summary,
        cached: false,
        regenerated: force,
        generatedAt: now,
      }
    } catch (e) {
      console.error('Summarization error:', e)
      set.status = 500
      return { message: 'AI summarization failed' }
    }
  }, {
    query: t.Object({
      force: t.Optional(t.String()),
    }),
    requireAuth: true
  })
