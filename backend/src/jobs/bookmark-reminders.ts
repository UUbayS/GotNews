import { prisma } from '../lib/prisma'
import { createNotification } from '../services/notifications'

const REMINDER_AGE_HOURS = Number(process.env.BOOKMARK_REMINDER_HOURS ?? 24)
const MAX_PER_RUN = Number(process.env.BOOKMARK_REMINDER_MAX_PER_RUN ?? 200)

export async function bookmarkReminderJob() {
  const cutoff = new Date(Date.now() - REMINDER_AGE_HOURS * 60 * 60 * 1000)

  const stale = await prisma.bookmark.findMany({
    where: {
      remindedAt: null,
      createdAt: { lt: cutoff }
    },
    include: {
      article: {
        select: { id: true, title: true, readingHistory: { select: { userId: true, articleId: true } } }
      }
    },
    take: MAX_PER_RUN
  })

  if (stale.length === 0) {
    console.log('[BookmarkReminder] No stale bookmarks to remind.')
    return { sent: 0 }
  }

  let sent = 0
  const now = new Date()

  for (const bookmark of stale) {
    const read = bookmark.article.readingHistory.some((h) => h.userId === bookmark.userId)
    if (read) {
      await prisma.bookmark.update({
        where: { id: bookmark.id },
        data: { remindedAt: now }
      })
      continue
    }

    await createNotification(
      bookmark.userId,
      'Belum Selesai Dibaca',
      `Anda menyimpan "${bookmark.article.title.substring(0, 60)}${bookmark.article.title.length > 60 ? '...' : ''}" ${REMINDER_AGE_HOURS} jam lalu. Mau selesaikan sekarang?`,
      'reminder'
    )

    await prisma.bookmark.update({
      where: { id: bookmark.id },
      data: { remindedAt: now }
    })
    sent++
  }

  console.log(`[BookmarkReminder] Sent ${sent} reminder(s).`)
  return { sent }
}
