import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { password } from '../lib/password'
import { authPlugin } from '../middleware/auth'
import { rateLimit } from '../lib/rate-limit'
import { resizeImage } from '../lib/image-resize'
import { mkdir } from 'fs/promises'
import { existsSync } from 'fs'
import { join } from 'path'

export const authRoutes = new Elysia({ prefix: '/api/auth' })
  .use(authPlugin)
  .use(rateLimit('auth', 30, 60000, true)) // 30 requests per minute per user
  
  // REGISTER
  .post('/register', async ({ body, jwt, jwtRefresh, set }) => {
    const { username, email, dateOfBirth, password: plainPassword } = body
    
    const existingEmail = await prisma.user.findUnique({ where: { email } })
    if (existingEmail) {
      set.status = 400
      return { message: 'Email already exists' }
    }

    const existingUsername = await prisma.user.findUnique({ where: { username } })
    if (existingUsername) {
      set.status = 400
      return { message: 'Username already taken' }
    }

    const hashedPassword = await password.hash(plainPassword)
    
    const user = await prisma.user.create({
      data: { name: username, username, email, password: hashedPassword, dateOfBirth }
    })

    const accessToken = await jwt.sign({ id: user.id, role: user.role })
    const refreshToken = await jwtRefresh.sign({ id: user.id, role: user.role })

    return {
      user: { id: user.id, name: user.name, username: user.username, email: user.email, dateOfBirth: user.dateOfBirth, role: user.role },
      accessToken,
      refreshToken
    }
  }, {
    body: t.Object({
      username: t.String({ minLength: 1 }),
      email: t.String({ format: 'email' }),
      dateOfBirth: t.Optional(t.String()),
      password: t.String({ minLength: 6 })
    })
  })

  // LOGIN
  .post('/login', async ({ body, jwt, jwtRefresh, set }) => {
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
      set.status = 401
      return { message: 'Invalid credentials' }
    }

    const isValid = await password.verify(plainPassword, user.password)
    if (!isValid) {
      set.status = 401
      return { message: 'Invalid credentials' }
    }

    const accessToken = await jwt.sign({ id: user.id, role: user.role })
    const refreshToken = await jwtRefresh.sign({ id: user.id, role: user.role })

    await prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() }
    }).catch(() => {})

    return {
      user: { 
        id: user.id, 
        name: user.name, 
        username: user.username,
        email: user.email, 
        avatarUrl: user.avatarUrl,
        dateOfBirth: user.dateOfBirth,
        gender: user.gender,
        address: user.address,
        role: user.role
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
  .post('/refresh', async ({ body, jwt, jwtRefresh, set }) => {
    const { refreshToken } = body
    
    const payload = await jwtRefresh.verify(refreshToken)
    if (!payload || !payload.id) {
      set.status = 401
      return { message: 'Invalid or expired refresh token' }
    }

    const user = await prisma.user.findUnique({ where: { id: payload.id as string } })
    if (!user) {
      set.status = 401
      return { message: 'User not found' }
    }

    const newAccessToken = await jwt.sign({ id: user.id, role: user.role })
    return { accessToken: newAccessToken }
  }, {
    body: t.Object({
      refreshToken: t.String()
    })
  })

  // GET CURRENT USER (Protected)
  .get('/me', async ({ user, set }) => {
    if (!user || !user.id) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const userData = await prisma.user.findUnique({
      where: { id: user.id },
      select: {
        id: true,
        name: true,
        username: true,
        email: true,
        role: true,
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

    if (!userData) {
      set.status = 404
      return { message: 'User not found' }
    }
    
    return { user: userData }
  }, {
    requireAuth: true
  })

  // LOGOUT (Protected)
  .post('/logout', async ({ rawToken, set }) => {
    if (!rawToken) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    // Decode JWT to get expiry without verifying (already verified by middleware)
    const payload = JSON.parse(
      Buffer.from(rawToken.split('.')[1]!, 'base64').toString('ascii')
    )
    const expiresAt = new Date(payload.exp * 1000)

    await prisma.invalidatedToken.create({
      data: { token: rawToken, expiresAt }
    })

    return { message: 'Logged out successfully' }
  }, { requireAuth: true })

  // UPDATE PROFILE (Protected)
  .put('/profile', async ({ body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const { name, username, email, dateOfBirth, gender, address, avatarUrl } = body

    if (email) {
      const existingEmail = await prisma.user.findUnique({ where: { email } })
      if (existingEmail && existingEmail.id !== user.id) {
        set.status = 400
        return { message: 'Email already in use by another account' }
      }
    }

    if (username) {
      const existingUsername = await prisma.user.findUnique({ where: { username } })
      if (existingUsername && existingUsername.id !== user.id) {
        set.status = 400
        return { message: 'Username already in use' }
      }
    }

    const updatedUser = await prisma.user.update({
      where: { id: user.id },
      data: { name, username, email, dateOfBirth, gender, address, avatarUrl },
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
      avatarUrl: t.Optional(t.String()),
    }),
    requireAuth: true
  })

  // UPLOAD AVATAR (Protected)
  .post('/avatar', async ({ body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const { file } = body as { file: File }
    if (!file) {
      set.status = 400
      return { message: 'No file provided' }
    }

    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/jpg']
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif']
    const ext = file.name.split('.').pop()?.toLowerCase() || ''
    
    if (!allowedTypes.includes(file.type) && !allowedExtensions.includes(ext)) {
      set.status = 400
      return { message: 'Invalid file type. Allowed: JPEG, PNG, WebP, GIF (or .jpg, .jpeg, .png, .webp, .gif)' }
    }

    const maxSize = 5 * 1024 * 1024 // 5MB
    if (file.size > maxSize) {
      set.status = 400
      return { message: 'File too large. Max size: 5MB' }
    }

    const uploadDir = join(process.cwd(), 'uploads', 'avatars')
    if (!existsSync(uploadDir)) {
      await mkdir(uploadDir, { recursive: true })
    }

    const safeExt = allowedExtensions.includes(ext) ? ext : 'jpg'
    const filename = `${user.id}-${Date.now()}.${safeExt}`
    const filepath = join(uploadDir, filename)

    const buffer = Buffer.from(await file.arrayBuffer())
    const resizedBuffer = await resizeImage(buffer, safeExt, 512, 512)
    await Bun.write(filepath, resizedBuffer)

    const avatarUrl = `/uploads/avatars/${filename}`

    await prisma.user.update({
      where: { id: user.id },
      data: { avatarUrl }
    })

    return { success: true, avatarUrl }
  }, { requireAuth: true })

  // GET PREFERENCES (Protected)
  .get('/preferences', async ({ user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const userData = await prisma.user.findUnique({
      where: { id: user.id },
      select: { preferences: true }
    })

    const preferences = JSON.parse(userData?.preferences || '[]')
    return { preferences }
  }, { requireAuth: true })

  // UPDATE PREFERENCES (Protected)
  .put('/preferences', async ({ body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const { preferences } = body
    await prisma.user.update({
      where: { id: user.id },
      data: { preferences: JSON.stringify(preferences) }
    })

    return { success: true, preferences }
  }, {
    body: t.Object({
      preferences: t.Array(t.String())
    }),
    requireAuth: true
  })

  // GET NOTIFICATIONS (Protected)
  .get('/notifications', async ({ user, query, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const page = parseInt(query.page || '1')
    const limit = parseInt(query.limit || '20')
    const skip = (page - 1) * limit

    const [notifications, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: { userId: user.id },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      prisma.notification.count({
        where: { userId: user.id, isRead: false }
      })
    ])

    return { notifications, unreadCount }
  }, {
    requireAuth: true
  })

  // MARK NOTIFICATION AS READ (Protected)
  .put('/notifications/:id/read', async ({ params, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const notification = await prisma.notification.findUnique({ where: { id: params.id } })
    if (!notification || notification.userId !== user.id) {
      set.status = 404
      return { message: 'Notification not found' }
    }

    await prisma.notification.update({
      where: { id: params.id },
      data: { isRead: true }
    })

    return { success: true }
  }, { requireAuth: true })

  // MARK ALL NOTIFICATIONS AS READ (Protected)
  .put('/notifications/read-all', async ({ user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    await prisma.notification.updateMany({
      where: { userId: user.id, isRead: false },
      data: { isRead: true }
    })

    return { success: true }
  }, { requireAuth: true })

  // DELETE OWN ACCOUNT (Protected)
  .delete('/account', async ({ user, rawToken, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    try {
      const userData = await prisma.user.findUnique({ where: { id: user.id }, select: { role: true } })
      if (userData?.role === 'admin') {
        const adminCount = await prisma.user.count({ where: { role: 'admin' } })
        if (adminCount <= 1) {
          set.status = 400
          return { message: 'Cannot delete the only administrator' }
        }
      }

      await prisma.user.delete({ where: { id: user.id } })

      if (rawToken) {
        const payload = JSON.parse(Buffer.from(rawToken.split('.')[1]!, 'base64').toString('ascii'))
        const expiresAt = new Date(payload.exp * 1000)
        await prisma.invalidatedToken.create({ data: { token: rawToken, expiresAt } }).catch(() => {})
      }

      return { success: true, message: 'Account deleted successfully' }
    } catch (e) {
      console.error('[Auth] Account deletion error:', e)
      set.status = 500
      return { message: 'Failed to delete account' }
    }
  }, { requireAuth: true })
