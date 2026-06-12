import { prisma } from './lib/prisma'

async function rebuildSearchVectors() {
  try {
    const result = await prisma.$executeRawUnsafe(`
      UPDATE "Article"
      SET "searchVector" = 
        setweight(to_tsvector('simple', coalesce("title", '')), 'A') ||
        setweight(to_tsvector('simple', coalesce("summary", '')), 'B') ||
        setweight(to_tsvector('simple', coalesce("originalContent", '')), 'C')
      WHERE "searchVector" IS NULL
    `)
    console.log(`Rebuilt search vectors for ${result} articles`)
  } catch (e) {
    console.error('Failed to rebuild search vectors:', e)
  } finally {
    await prisma.$disconnect()
  }
}

rebuildSearchVectors()
