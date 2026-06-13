import { prisma } from './src/lib/prisma'

// Recreate the full-text search GIN indexes that Prisma's `migrate dev`
// dropped as "drift" because they live in run-migration.ts (not schema.prisma).
const statements = [
  `CREATE EXTENSION IF NOT EXISTS pg_trgm`,
  `CREATE INDEX IF NOT EXISTS idx_article_search ON "Article" USING GIN("searchVector")`,
  `CREATE INDEX IF NOT EXISTS idx_article_title_trgm ON "Article" USING GIN(title gin_trgm_ops)`,
]

try {
  for (const sql of statements) {
    await prisma.$executeRawUnsafe(sql)
  }
  console.log('✅ Search indexes recreated')
} catch (e: any) {
  console.error('❌ Failed:', e.message)
  process.exit(1)
} finally {
  await prisma.$disconnect()
}
