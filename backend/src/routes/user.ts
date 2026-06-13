import { Elysia, t } from 'elysia'
import { prisma } from '../lib/prisma'
import { authPlugin } from '../middleware/auth'

export const userRoutes = new Elysia({ prefix: '/api/user' })
  .use(authPlugin)

  .put('/location', async ({ body, user, set }) => {
    if (!user) {
      set.status = 401
      return { message: 'Unauthorized' }
    }

    const { latitude, longitude, countryCode, city, enabled } = body

    if (enabled && (typeof latitude !== 'number' || typeof longitude !== 'number')) {
      set.status = 400
      return { message: 'latitude and longitude are required when enabled=true' }
    }

    if (latitude !== undefined && (latitude < -90 || latitude > 90)) {
      set.status = 400
      return { message: 'Invalid latitude' }
    }
    if (longitude !== undefined && (longitude < -180 || longitude > 180)) {
      set.status = 400
      return { message: 'Invalid longitude' }
    }

    const updated = await prisma.user.update({
      where: { id: user.id },
      data: {
        ...(latitude !== undefined ? { latitude } : {}),
        ...(longitude !== undefined ? { longitude } : {}),
        ...(countryCode !== undefined ? { countryCode } : {}),
        ...(city !== undefined ? { city } : {}),
        ...(enabled !== undefined ? { locationEnabled: enabled } : {}),
        locationUpdatedAt: new Date(),
      },
      select: {
        latitude: true,
        longitude: true,
        countryCode: true,
        city: true,
        locationEnabled: true,
        locationUpdatedAt: true,
      },
    })

    return { success: true, location: updated }
  }, {
    body: t.Object({
      latitude: t.Optional(t.Number()),
      longitude: t.Optional(t.Number()),
      countryCode: t.Optional(t.String({ maxLength: 2 })),
      city: t.Optional(t.String({ maxLength: 100 })),
      enabled: t.Optional(t.Boolean()),
    }),
    requireAuth: true,
  })