import { PrismaClient } from '@prisma/client'
import { password } from './lib/password'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Seeding database...')

  const adminEmail = 'admin@gotnews.com'
  const adminUsername = 'admin'

  const existing = await prisma.user.findFirst({
    where: {
      OR: [
        { email: adminEmail },
        { username: adminUsername }
      ]
    }
  })

  if (existing) {
    console.log('⚠️ Admin user already exists. Skipping.')
    return
  }

  const hashedPassword = await password.hash('admin123')

  const admin = await prisma.user.create({
    data: {
      name: 'Administrator',
      username: adminUsername,
      email: adminEmail,
      password: hashedPassword,
      role: 'admin'
    }
  })

  console.log(`✅ Successfully created admin user: ${admin.email}`)
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
