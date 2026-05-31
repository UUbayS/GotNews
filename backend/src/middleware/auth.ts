import { Elysia, t } from 'elysia'
import { jwt } from '@elysiajs/jwt'
import { prisma } from '../lib/prisma'

const JWT_SECRET = process.env.JWT_SECRET
if (!JWT_SECRET) {
  throw new Error('JWT_SECRET environment variable is required!')
}

export async function cleanupExpiredTokens() {
  await prisma.invalidatedToken.deleteMany({
    where: { expiresAt: { lt: new Date() } }
  })
}

export const authPlugin = new Elysia()
  .use(
    jwt({
      name: 'jwt',
      secret: JWT_SECRET,
      exp: '1h' // access token expires in 1 hour
    })
  )
  .use(
    jwt({
      name: 'jwtRefresh',
      secret: JWT_SECRET,
      exp: '7d' // refresh token expires in 7 days
    })
  )
  .derive({ as: 'global' }, async ({ jwt, headers, request }) => {
    const auth = headers['authorization']
    const token = auth?.startsWith('Bearer ') ? auth.slice(7) : null

    if (!token) {
      return { user: null, rawToken: null }
    }

    const isRevoked = await prisma.invalidatedToken.findUnique({ where: { token } })
    if (isRevoked) {
      return { user: null, rawToken: null }
    }

    try {
      const payload = await jwt.verify(token)
      if (!payload || !payload.id) {
        return { user: null, rawToken: null }
      }

      return { user: { id: payload.id as string, role: (payload.role as string) || 'user' }, rawToken: token }
    } catch (e) {
      return { user: null, rawToken: null }
    }
  })
  .macro({
    requireAuth(enabled: boolean) {
      if (enabled) {
        return {
          beforeHandle({ user, set }: any) {
            if (!user || !user.id) {
              set.status = 401
              return { message: 'Unauthorized' }
            }
          }
        }
      }
    },
    requireAdmin(enabled: boolean) {
      if (enabled) {
        return {
          beforeHandle({ user, set }: any) {
            if (!user || !user.id) {
              set.status = 401
              return { message: 'Unauthorized' }
            }
            if (user.role !== 'admin') {
              set.status = 403
              return { message: 'Forbidden: admin access required' }
            }
          }
        }
      }
    }
  })