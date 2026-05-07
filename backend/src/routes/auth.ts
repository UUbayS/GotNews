import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { password } from '../lib/password'
import { authPlugin } from '../middleware/auth'

export const authRoutes = new Elysia({ prefix: '/api/auth' })
  .use(authPlugin)
  
  // REGISTER
  .post('/register', async ({ body, jwt, jwtRefresh, error }) => {
    const { name, email, password: plainPassword } = body
    
    const existingUser = await prisma.user.findUnique({ where: { email } })
    if (existingUser) {
      return error(400, { message: 'Email already exists' })
    }

    const hashedPassword = await password.hash(plainPassword)
    
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword
      }
    })

    const accessToken = await jwt.sign({ id: user.id })
    const refreshToken = await jwtRefresh.sign({ id: user.id })

    return {
      user: { id: user.id, name: user.name, email: user.email },
      accessToken,
      refreshToken
    }
  }, {
    body: t.Object({
      name: t.String({ minLength: 2 }),
      email: t.String({ format: 'email' }),
      password: t.String({ minLength: 6 })
    })
  })

  // LOGIN
  .post('/login', async ({ body, jwt, jwtRefresh, error }) => {
    const { email, password: plainPassword } = body
    
    const user = await prisma.user.findUnique({ where: { email } })
    if (!user) {
      return error(401, { message: 'Invalid email or password' })
    }

    const isValid = await password.verify(plainPassword, user.password)
    if (!isValid) {
      return error(401, { message: 'Invalid email or password' })
    }

    const accessToken = await jwt.sign({ id: user.id })
    const refreshToken = await jwtRefresh.sign({ id: user.id })

    return {
      user: { id: user.id, name: user.name, email: user.email, avatarUrl: user.avatarUrl },
      accessToken,
      refreshToken
    }
  }, {
    body: t.Object({
      email: t.String({ format: 'email' }),
      password: t.String()
    })
  })

  // REFRESH TOKEN
  .post('/refresh', async ({ body, jwt, jwtRefresh, error }) => {
    const { refreshToken } = body
    
    const payload = await jwtRefresh.verify(refreshToken)
    if (!payload || !payload.id) {
      return error(401, { message: 'Invalid or expired refresh token' })
    }

    const user = await prisma.user.findUnique({ where: { id: payload.id as string } })
    if (!user) {
      return error(401, { message: 'User not found' })
    }

    const newAccessToken = await jwt.sign({ id: user.id })
    
    return {
      accessToken: newAccessToken
    }
  }, {
    body: t.Object({
      refreshToken: t.String()
    })
  })

  // GET CURRENT USER (Protected)
  .get('/me', async ({ user, error }) => {
    const userData = await prisma.user.findUnique({
      where: { id: user?.id },
      select: {
        id: true,
        name: true,
        email: true,
        avatarUrl: true,
        createdAt: true,
        _count: {
          select: { bookmarks: true, likes: true }
        }
      }
    })

    if (!userData) return error(404, { message: 'User not found' })
    
    return { user: userData }
  }, {
    requireAuth: true
  })
