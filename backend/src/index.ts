import { Elysia } from 'elysia'
import { cors } from '@elysiajs/cors'
import { cron } from '@elysiajs/cron'
import { authRoutes } from './routes/auth'
import { interactionRoutes } from './routes/interaction'
import { feedRoutes } from './routes/feed'
import { aiRoutes } from './routes/ai'
import { syncNewsJob } from './jobs/sync-news'

const app = new Elysia()
  .use(cors())
  
  // Cron Job: Run every 30 minutes
  .use(
    cron({
      name: 'sync-news',
      pattern: '*/30 * * * *',
      run() {
        syncNewsJob()
      }
    })
  )

  // API Routes
  .use(authRoutes)
  .use(feedRoutes)
  .use(interactionRoutes)
  .use(aiRoutes)

  // Trigger sync manually for testing
  .get('/api/sync', async () => {
    await syncNewsJob()
    return { success: true, message: 'Sync triggered' }
  })

  .get('/', () => 'NewsScroll API is running 🚀')
  .listen(3000)

console.log(`🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`)

// Run initial sync on startup (optional, commented out by default)
// syncNewsJob()
