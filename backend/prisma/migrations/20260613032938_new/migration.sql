/*
  Warnings:

  - You are about to drop the column `search_vector` on the `Article` table. All the data in the column will be lost.

*/
-- DropIndex
DROP INDEX "idx_article_search";

-- DropIndex
DROP INDEX "idx_article_title_trgm";

-- AlterTable
ALTER TABLE "Article" DROP COLUMN "search_vector",
ADD COLUMN     "searchVector" tsvector;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "lastLoginAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "BookmarkFolder" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BookmarkFolder_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BookmarkFolderItem" (
    "id" TEXT NOT NULL,
    "folderId" TEXT NOT NULL,
    "bookmarkId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "BookmarkFolderItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SearchHistory" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "query" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SearchHistory_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "BookmarkFolder_userId_idx" ON "BookmarkFolder"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "BookmarkFolder_userId_name_key" ON "BookmarkFolder"("userId", "name");

-- CreateIndex
CREATE INDEX "BookmarkFolderItem_folderId_idx" ON "BookmarkFolderItem"("folderId");

-- CreateIndex
CREATE UNIQUE INDEX "BookmarkFolderItem_folderId_bookmarkId_key" ON "BookmarkFolderItem"("folderId", "bookmarkId");

-- CreateIndex
CREATE INDEX "SearchHistory_userId_createdAt_idx" ON "SearchHistory"("userId", "createdAt" DESC);

-- AddForeignKey
ALTER TABLE "BookmarkFolderItem" ADD CONSTRAINT "BookmarkFolderItem_folderId_fkey" FOREIGN KEY ("folderId") REFERENCES "BookmarkFolder"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BookmarkFolderItem" ADD CONSTRAINT "BookmarkFolderItem_bookmarkId_fkey" FOREIGN KEY ("bookmarkId") REFERENCES "Bookmark"("id") ON DELETE CASCADE ON UPDATE CASCADE;
