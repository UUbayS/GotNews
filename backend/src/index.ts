import { Elysia } from 'elysia'
import { cors } from '@elysiajs/cors'
import { cron } from '@elysiajs/cron'
import { authPlugin, cleanupExpiredTokens } from './middleware/auth'
import { authRoutes } from './routes/auth'
import { interactionRoutes } from './routes/interaction'
import { feedRoutes } from './routes/feed'
import { searchRoutes } from './routes/search'
import { aiRoutes } from './routes/ai'
import { adminRoutes } from './routes/admin'
import { syncNewsJob } from './jobs/sync-news'
import { readFileSync, existsSync } from 'fs'
import { join } from 'path'

const app = new Elysia()
  .use(cors({
    origin: '*',
    allowedHeaders: ['Content-Type', 'Authorization'],
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
  }))
  
  .use(authPlugin)
  
  // Cron Job: Run every 30 minutes
  .use(
    cron({
      name: 'sync-news',
      pattern: '*/30 * * * *',
      run: async () => {
        await syncNewsJob()
      }
    })
  )

  // Cron Job: Cleanup expired tokens every hour
  .use(
    cron({
      name: 'cleanup-tokens',
      pattern: '0 * * * *',
      run: async () => {
        await cleanupExpiredTokens()
      }
    })
  )

  // API Routes
  .use(authRoutes)
  .use(feedRoutes)
  .use(searchRoutes)
  .use(interactionRoutes)
  .use(aiRoutes)
  .use(adminRoutes)

  .onError(({ code, error, set }) => {
    const msg = (error as any)?.message || String(error)
    console.error(`[Global Error] ${code}:`, msg)
    set.status = set.status || 500
    return {
      message: code === 'VALIDATION' 
        ? msg
        : 'Internal server error',
      code
    }
  })

  .get('/', () => 'NewsScroll API is running 🚀')

  // Serve uploaded files
  .get('/uploads/avatars/:filename', ({ params, set }) => {
    const filepath = join(process.cwd(), 'uploads', 'avatars', params.filename)
    if (!existsSync(filepath)) {
      set.status = 404
      return { message: 'File not found' }
    }
    const file = Bun.file(filepath)
    const ext = params.filename.split('.').pop()?.toLowerCase() || 'jpg'
    const mimeTypes: Record<string, string> = {
      jpg: 'image/jpeg',
      jpeg: 'image/jpeg',
      png: 'image/png',
      webp: 'image/webp',
      gif: 'image/gif',
    }
    set.headers['Content-Type'] = mimeTypes[ext] || 'application/octet-stream'
    return file
  })

  .listen(3000)

console.log(`🦊 Elysia is running at ${app.server?.hostname}:${app.server?.port}`)