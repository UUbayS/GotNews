import { Elysia, t } from 'elysia'
import { jwt } from '@elysiajs/jwt'
import { prisma } from '../lib/prisma'

export const authPlugin = new Elysia()
  .use(
    jwt({
      name: 'jwt',
      secret: process.env.JWT_SECRET || 'super-secret-jwt-key-change-in-prod',
      exp: '1h' // access token expires in 1 hour
    })
  )
  .use(
    jwt({
      name: 'jwtRefresh',
      secret: process.env.JWT_SECRET || 'super-secret-jwt-key-change-in-prod',
      exp: '7d' // refresh token expires in 7 days
    })
  )
  .derive(async ({ jwt, headers }) => {
    const auth = headers['authorization']
    const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null
    
    if (!token) {
      return { user: null }
    }

    const payload = await jwt.verify(token)
    if (!payload || !payload.id) {
      return { user: null }
    }

    return { user: { id: payload.id as string } }
  })
  .macro(({ onBeforeHandle }) => ({
    requireAuth() {
      onBeforeHandle(({ user, set }) => {
        if (!user) {
          set.status = 401
          return { message: 'Unauthorized' }
        }
      })
    }
  }))
