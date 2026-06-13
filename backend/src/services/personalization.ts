import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export interface UserContext {
  id: string
  countryCode: string | null
  locationEnabled: boolean
  topBookmarkCategories: string[]
  topDurationCategories: Record<string, number>
}

export interface ArticleScore {
  id: string
  category: string | null
  country: string | null
  createdAt: Date
  likes24h: number
}

const RECENCY_MAX = 100
const COUNTRY_BOOST = 200
const BOOKMARK_BOOST = 150
const DURATION_BOOST_MAX = 100
const TRENDING_BOOST = 50
const TRENDING_THRESHOLD = 5

export function scoreArticle(article: ArticleScore, user: UserContext | null): number {
  const ageHours = (Date.now() - article.createdAt.getTime()) / 3_600_000
  let score = Math.max(0, RECENCY_MAX - ageHours * 0.5)

  if (!user) return score

  if (user.locationEnabled && user.countryCode && article.country === user.countryCode) {
    score += COUNTRY_BOOST
  }

  if (article.category && user.topBookmarkCategories.includes(article.category)) {
    score += BOOKMARK_BOOST
  }

  if (article.category) {
    const durWeight = user.topDurationCategories[article.category] ?? 0
    score += durWeight * DURATION_BOOST_MAX
  }

  if (article.likes24h >= TRENDING_THRESHOLD) {
    score += TRENDING_BOOST
  }

  return score
}

export async function buildUserContext(
  userId: string
): Promise<UserContext | null> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, countryCode: true, locationEnabled: true },
  })
  if (!user) return null

  const bookmarks = await prisma.bookmark.findMany({
    where: { userId },
    include: { article: { select: { category: true } } },
    take: 50,
  })
  const topBookmarkCategories = [
    ...new Set(
      bookmarks
        .map((b) => b.article.category)
        .filter((c): c is string => !!c)
    ),
  ].slice(0, 5)

  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
  const durationRows = await prisma.readingHistory.findMany({
    where: { userId, readAt: { gte: thirtyDaysAgo }, durationSec: { gt: 0 } },
    include: { article: { select: { category: true } } },
  })
  const totalsByCategory: Record<string, number> = {}
  let totalDuration = 0
  for (const row of durationRows) {
    const cat = row.article.category
    if (!cat) continue
    totalsByCategory[cat] = (totalsByCategory[cat] ?? 0) + row.durationSec
    totalDuration += row.durationSec
  }
  const topDurationCategories: Record<string, number> = {}
  if (totalDuration > 0) {
    for (const [cat, total] of Object.entries(totalsByCategory)) {
      topDurationCategories[cat] = total / totalDuration
    }
  }

  return {
    id: user.id,
    countryCode: user.countryCode,
    locationEnabled: user.locationEnabled,
    topBookmarkCategories,
    topDurationCategories,
  }
}

export { prisma }