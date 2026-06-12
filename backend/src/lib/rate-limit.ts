import { Elysia } from 'elysia'

interface RateLimitEntry {
  count: number
  resetAt: number
}

const stores = new Map<string, Map<string, RateLimitEntry>>()

export function rateLimit(storeName: string, maxRequests: number, windowMs: number, useUserId = false) {
  return new Elysia()
    .derive({ as: 'scoped' }, ({ request, set, user }: any) => {
      const key = useUserId && user?.id
        ? `user:${user.id}`
        : request.headers.get('x-forwarded-for') || 'anonymous'
      const now = Date.now()

      if (!stores.has(storeName)) {
        stores.set(storeName, new Map())
      }
      const store = stores.get(storeName)!

      let entry = store.get(key)
      if (!entry || now > entry.resetAt) {
        entry = { count: 0, resetAt: now + windowMs }
      }

      entry.count++
      store.set(key, entry)

      set.headers['X-RateLimit-Limit'] = String(maxRequests)
      set.headers['X-RateLimit-Remaining'] = String(Math.max(0, maxRequests - entry.count))
      set.headers['X-RateLimit-Reset'] = String(Math.ceil(entry.resetAt / 1000))

      if (entry.count > maxRequests) {
        set.status = 429
        return { rateLimitExceeded: true }
      }

      return { rateLimitExceeded: false }
    })
    .onBeforeHandle({ as: 'scoped' }, ({ rateLimitExceeded }) => {
      if (rateLimitExceeded) {
        return { message: 'Too many requests. Please try again later.' }
      }
    })
}
