import { Elysia } from 'elysia'
import { prisma } from '../lib/prisma'
import { authPlugin } from '../middleware/auth'

export const analyticsRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)

  .get('/analytics/reading-stats', async ({ user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const userId = user.id

      const totalArticlesRead = await prisma.readingHistory.count({ where: { userId } })

      const readingHistory = await prisma.readingHistory.findMany({
        where: { userId },
        include: { article: { select: { category: true } } },
        orderBy: { readAt: 'desc' },
        take: 500
      })

      const categoryCounts: Record<string, number> = {}
      let totalProgress = 0
      for (const h of readingHistory) {
        const cat = h.article?.category || 'unknown'
        categoryCounts[cat] = (categoryCounts[cat] || 0) + 1
        totalProgress += h.readProgress
      }

      const topCategories = Object.entries(categoryCounts)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .map(([category, count]) => ({ category, count }))

      const avgReadProgress = readingHistory.length > 0
        ? Math.round((totalProgress / readingHistory.length) * 100)
        : 0

      const weekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
      const weeklyHistory = readingHistory.filter(h => h.readAt >= weekAgo)

      const dailyActivity: Record<string, number> = {}
      for (let i = 6; i >= 0; i--) {
        const date = new Date(Date.now() - i * 24 * 60 * 60 * 1000)
        const key = date.toISOString().split('T')[0]!
        dailyActivity[key] = 0
      }
      for (const h of weeklyHistory) {
        const key = h.readAt.toISOString().split('T')[0]!
        if (dailyActivity[key] !== undefined) {
          dailyActivity[key]++
        }
      }

      const readDays = new Set(readingHistory.map(h => h.readAt.toISOString().split('T')[0]))
      let streakDays = 0
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      for (let i = 0; i < 365; i++) {
        const checkDate = new Date(today)
        checkDate.setDate(checkDate.getDate() - i)
        const key = checkDate.toISOString().split('T')[0]!
        if (readDays.has(key)) {
          streakDays++
        } else if (i > 0) {
          break
        }
      }

      return {
        totalArticlesRead,
        avgReadProgress,
        topCategories,
        weeklyActivity: Object.entries(dailyActivity).map(([date, count]) => ({ date, count })),
        streakDays
      }
    } catch (e) {
      console.error('[Analytics] Failed to fetch reading stats:', e)
      set.status = 500
      return { message: 'Failed to fetch reading stats' }
    }
  })
