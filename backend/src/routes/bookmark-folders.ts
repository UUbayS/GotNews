import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { authPlugin } from '../middleware/auth'

export const bookmarkFolderRoutes = new Elysia({ prefix: '/api' })
  .use(authPlugin)

  .get('/bookmark-folders', async ({ user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const folders = await prisma.bookmarkFolder.findMany({
        where: { userId: user.id },
        include: { _count: { select: { items: true } } },
        orderBy: { createdAt: 'asc' }
      })

      return {
        data: folders.map(f => ({
          id: f.id,
          name: f.name,
          count: f._count.items,
          createdAt: f.createdAt
        }))
      }
    } catch (e) {
      console.error('[BookmarkFolders] Failed to list folders:', e)
      set.status = 500
      return { message: 'Failed to list folders' }
    }
  })

  .post('/bookmark-folders', async ({ body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const folder = await prisma.bookmarkFolder.create({
        data: { userId: user.id, name: body.name }
      })
      return { success: true, data: { id: folder.id, name: folder.name } }
    } catch (e: any) {
      if (e?.code === 'P2002') {
        set.status = 400
        return { message: 'Folder with this name already exists' }
      }
      console.error('[BookmarkFolders] Failed to create folder:', e)
      set.status = 500
      return { message: 'Failed to create folder' }
    }
  }, {
    body: t.Object({ name: t.String({ minLength: 1, maxLength: 50 }) })
  })

  .delete('/bookmark-folders/:id', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const folder = await prisma.bookmarkFolder.findUnique({ where: { id: params.id } })
      if (!folder || folder.userId !== user.id) {
        set.status = 404
        return { message: 'Folder not found' }
      }

      await prisma.bookmarkFolder.delete({ where: { id: params.id } })
      return { success: true }
    } catch (e) {
      console.error('[BookmarkFolders] Failed to delete folder:', e)
      set.status = 500
      return { message: 'Failed to delete folder' }
    }
  })

  .post('/bookmark-folders/:id/items', async ({ params, body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const folder = await prisma.bookmarkFolder.findUnique({ where: { id: params.id } })
      if (!folder || folder.userId !== user.id) {
        set.status = 404
        return { message: 'Folder not found' }
      }

      const bookmark = await prisma.bookmark.findUnique({
        where: { userId_articleId: { userId: user.id, articleId: body.bookmarkId } }
      })
      if (!bookmark) {
        set.status = 404
        return { message: 'Bookmark not found' }
      }

      await prisma.bookmarkFolderItem.create({
        data: { folderId: params.id, bookmarkId: body.bookmarkId }
      })

      return { success: true }
    } catch (e: any) {
      if (e?.code === 'P2002') {
        set.status = 400
        return { message: 'Article already in this folder' }
      }
      console.error('[BookmarkFolders] Failed to add item:', e)
      set.status = 500
      return { message: 'Failed to add item to folder' }
    }
  }, {
    body: t.Object({ bookmarkId: t.String() })
  })

  .delete('/bookmark-folders/:id/items/:itemId', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const folder = await prisma.bookmarkFolder.findUnique({ where: { id: params.id } })
      if (!folder || folder.userId !== user.id) {
        set.status = 404
        return { message: 'Folder not found' }
      }

      await prisma.bookmarkFolderItem.delete({ where: { id: params.itemId } })
      return { success: true }
    } catch (e) {
      console.error('[BookmarkFolders] Failed to remove item:', e)
      set.status = 500
      return { message: 'Failed to remove item from folder' }
    }
  })

  .get('/bookmark-folders/:id', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const folder = await prisma.bookmarkFolder.findUnique({
        where: { id: params.id },
        include: {
          items: {
            include: {
              bookmark: {
                include: {
                  article: {
                    include: { _count: { select: { likes: true } } }
                  }
                }
              }
            },
            orderBy: { createdAt: 'desc' }
          }
        }
      })

      if (!folder || folder.userId !== user.id) {
        set.status = 404
        return { message: 'Folder not found' }
      }

      const articleIds = folder.items.map(i => i.bookmark.articleId)
      const userLikes = await prisma.like.findMany({
        where: { userId: user.id, articleId: { in: articleIds } }
      })
      const likedSet = new Set(userLikes.map(l => l.articleId))

      return {
        data: {
          id: folder.id,
          name: folder.name,
          articles: folder.items.map(i => ({
            id: i.bookmark.article.id,
            title: i.bookmark.article.title,
            summary: i.bookmark.article.summary,
            imageUrl: i.bookmark.article.imageUrl,
            sourceName: i.bookmark.article.sourceName,
            category: i.bookmark.article.category,
            publishedAt: i.bookmark.article.publishedAt,
            likesCount: i.bookmark.article._count.likes,
            isLiked: likedSet.has(i.bookmark.article.id),
            isBookmarked: true,
            folderItemId: i.id
          }))
        }
      }
    } catch (e) {
      console.error('[BookmarkFolders] Failed to get folder:', e)
      set.status = 500
      return { message: 'Failed to get folder' }
    }
  })