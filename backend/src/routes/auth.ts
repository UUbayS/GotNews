import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { password } from '../lib/password'
import { authPlugin } from '../middleware/auth'

export const authRoutes = new Elysia({ prefix: '/api/auth' })
  .use(authPlugin)
  
  // REGISTER
  .post('/register', async ({ body, jwt, jwtRefresh, error }) => {
    const { firstName, lastName, email, dateOfBirth, password: plainPassword } = body
    
    const existingUser = await prisma.user.findUnique({ where: { email } })
    if (existingUser) {
      return error(400, { message: 'Email already exists' })
    }

    const hashedPassword = await password.hash(plainPassword)
    const name = `${firstName} ${lastName}`.trim()
    
    const user = await prisma.user.create({
      data: {
        name,
        email,
        password: hashedPassword,
        dateOfBirth
      }
    })

    const accessToken = await jwt.sign({ id: user.id })
    const refreshToken = await jwtRefresh.sign({ id: user.id })

    return {
      user: { id: user.id, name: user.name, email: user.email, dateOfBirth: user.dateOfBirth },
      accessToken,
      refreshToken
    }
  }, {
    body: t.Object({
      firstName: t.String({ minLength: 1 }),
      lastName: t.String({ minLength: 1 }),
      email: t.String({ format: 'email' }),
      dateOfBirth: t.Optional(t.String()),
      password: t.String({ minLength: 6 })
    })
  })

  // LOGIN
  .post('/login', async ({ body, jwt, jwtRefresh, error }) => {
    const { identifier, password: plainPassword } = body
    
    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier },
          { username: identifier }
        ]
      }
    })
    if (!user) {
      return error(401, { message: 'Invalid credentials' })
    }

    const isValid = await password.verify(plainPassword, user.password)
    if (!isValid) {
      return error(401, { message: 'Invalid credentials' })
    }

    const accessToken = await jwt.sign({ id: user.id })
    const refreshToken = await jwtRefresh.sign({ id: user.id })

    return {
      user: { 
        id: user.id, 
        name: user.name, 
        username: user.username,
        email: user.email, 
        avatarUrl: user.avatarUrl,
        dateOfBirth: user.dateOfBirth,
        gender: user.gender,
        address: user.address
      },
      accessToken,
      refreshToken
    }
  }, {
    body: t.Object({
      identifier: t.String(),
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
        username: true,
        email: true,
        avatarUrl: true,
        dateOfBirth: true,
        gender: true,
        address: true,
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

  // UPDATE PROFILE (Protected)
  .put('/profile', async ({ body, user, error }) => {
    if (!user) return error(401, { message: 'Unauthorized' })

    const { name, username, email, dateOfBirth, gender, address } = body

    // Check if email is taken by someone else
    if (email) {
      const existingEmail = await prisma.user.findUnique({ where: { email } })
      if (existingEmail && existingEmail.id !== user.id) {
        return error(400, { message: 'Email already in use by another account' })
      }
    }

    // Check if username is taken by someone else
    if (username) {
      const existingUsername = await prisma.user.findUnique({ where: { username } })
      if (existingUsername && existingUsername.id !== user.id) {
        return error(400, { message: 'Username already in use' })
      }
    }

    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: {
        name,
        username,
        email,
        dateOfBirth,
        gender,
        address
      },
      select: {
        id: true,
        name: true,
        username: true,
        email: true,
        avatarUrl: true,
        dateOfBirth: true,
        gender: true,
        address: true,
      }
    })

    return { user: updatedUser }
  }, {
    body: t.Object({
      name: t.Optional(t.String()),
      username: t.Optional(t.String()),
      email: t.Optional(t.String({ format: 'email' })),
      dateOfBirth: t.Optional(t.String()),
      gender: t.Optional(t.String()),
      address: t.Optional(t.String()),
    }),
    requireAuth: true
  })
