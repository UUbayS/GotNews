-- DropIndex
DROP INDEX "idx_article_search";

-- DropIndex
DROP INDEX "idx_article_title_trgm";

-- AlterTable
ALTER TABLE "Article" ADD COLUMN     "country" TEXT;

-- AlterTable
ALTER TABLE "ReadingHistory" ADD COLUMN     "durationSec" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "city" TEXT,
ADD COLUMN     "countryCode" TEXT,
ADD COLUMN     "latitude" DOUBLE PRECISION,
ADD COLUMN     "locationEnabled" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "locationUpdatedAt" TIMESTAMP(3),
ADD COLUMN     "longitude" DOUBLE PRECISION;

-- CreateIndex
CREATE INDEX "Article_country_idx" ON "Article"("country");
