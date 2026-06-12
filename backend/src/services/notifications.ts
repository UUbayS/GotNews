import { prisma } from '../lib/prisma'

export async function createNotification(
  userId: string,
  title: string,
  message: string,
  type: 'info' | 'like' | 'bookmark' | 'system' = 'info'
) {
  try {
    await prisma.notification.create({
      data: { userId, title, message, type }
    })
  } catch (e) {
    console.error('[Notification] Failed to create notification:', e)
  }
}

export async function notifyNewArticleForUsers(articleTitle: string, category: string) {
  try {
    const users = await prisma.user.findMany({
      where: {
        role: 'user',
        preferences: { contains: category }
      },
      select: { id: true }
    })

    for (const user of users) {
      await createNotification(
        user.id,
        'New Article Available',
        `A new ${category} article is available: "${articleTitle.substring(0, 60)}${articleTitle.length > 60 ? '...' : ''}"`,
        'system'
      )
    }
  } catch (e) {
    console.error('[Notification] Failed to notify users about new article:', e)
  }
}
