import { prisma } from '../lib/prisma'

export type NotificationType = 'info' | 'like' | 'bookmark' | 'system' | 'breaking' | 'reminder'

export async function createNotification(
  userId: string,
  title: string,
  message: string,
  type: NotificationType = 'info'
) {
  try {
    await prisma.notification.create({
      data: { userId, title, message, type }
    })
  } catch (e) {
    console.error('[Notification] Failed to create notification:', e)
  }
}

export async function notifyNewArticleForUsers(
  articleTitle: string,
  category: string,
  options?: { isBreaking?: boolean; articleId?: string }
) {
  try {
    const users = await prisma.user.findMany({
      where: {
        role: 'user'
      },
      select: { id: true, preferences: true }
    })

    const subscribers = options?.isBreaking
      ? users
      : users.filter((u) => (u.preferences ?? '').includes(category))

    for (const user of subscribers) {
      await createNotification(
        user.id,
        options?.isBreaking ? 'Breaking News' : 'New Article Available',
        options?.isBreaking
          ? `"${articleTitle.substring(0, 80)}${articleTitle.length > 80 ? '...' : ''}"`
          : `A new ${category} article is available: "${articleTitle.substring(0, 60)}${articleTitle.length > 60 ? '...' : ''}"`,
        options?.isBreaking ? 'breaking' : 'system'
      )
    }
  } catch (e) {
    console.error('[Notification] Failed to notify users about new article:', e)
  }
}

export async function notifyBreakingArticle(articleId: string, title: string, userId?: string) {
  if (userId) {
    await createNotification(
      userId,
      'Breaking News',
      `"${title.substring(0, 80)}${title.length > 80 ? '...' : ''}"`,
      'breaking'
    )
    await prisma.article.update({
      where: { id: articleId },
      data: { isBreaking: true, breakingAt: new Date() }
    }).catch(() => {})
    return
  }
  await notifyNewArticleForUsers(title, '', { isBreaking: true, articleId })
}
