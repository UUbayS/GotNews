import { prisma } from '../lib/prisma'

export async function cleanupExpiredBansJob() {
  const now = new Date()
  console.log('🧹 Running expired-ban cleanup...')

  const expiredUsers = await prisma.user.findMany({
    where: {
      isBanned: true,
      banExpiresAt: { not: null, lte: now }
    },
    select: { id: true, email: true }
  })

  if (expiredUsers.length === 0) {
    console.log('✅ No expired bans to lift.')
    return
  }

  await prisma.$transaction(async (tx) => {
    for (const u of expiredUsers) {
      await tx.user.update({
        where: { id: u.id },
        data: {
          isBanned: false,
          bannedAt: null,
          bannedReason: null,
          bannedBy: null,
          banExpiresAt: null,
        }
      })
      await tx.bannedEmail.deleteMany({ where: { email: u.email } })
      console.log(`  ↳ Lifted ban for ${u.email}`)
    }
  })

  await prisma.bannedEmail.deleteMany({
    where: {
      expiresAt: { not: null, lte: now }
    }
  })

  console.log(`✅ Lifted ${expiredUsers.length} expired ban(s).`)
}
