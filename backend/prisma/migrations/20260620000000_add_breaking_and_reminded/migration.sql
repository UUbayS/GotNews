-- AlterTable
ALTER TABLE "Article" ADD COLUMN     "isBreaking" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "Article" ADD COLUMN     "breakingAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Bookmark" ADD COLUMN     "remindedAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "Article_isBreaking_breakingAt_idx" ON "Article"("isBreaking", "breakingAt" DESC);

-- CreateIndex
CREATE INDEX "Bookmark_remindedAt_idx" ON "Bookmark"("remindedAt");

-- CreateIndex
CREATE INDEX "Bookmark_userId_remindedAt_idx" ON "Bookmark"("userId", "remindedAt");
