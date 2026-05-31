import { Elysia } from 'elysia'
import { authPlugin } from '../middleware/auth'
import { syncNewsJob } from '../jobs/sync-news'

export const adminRoutes = new Elysia({ prefix: '/api/admin' })
  .use(authPlugin)

  .get('/sync', async () => {
    await syncNewsJob()
    return { success: true, message: 'Sync triggered' }
  }, { requireAdmin: true })
