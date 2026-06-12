-- Rebuild search_vector for all existing articles
-- This fixes the issue where old articles don't have search_vector populated

UPDATE "Article"
SET "searchVector" = 
  setweight(to_tsvector('simple', coalesce("title", '')), 'A') ||
  setweight(to_tsvector('simple', coalesce("summary", '')), 'B') ||
  setweight(to_tsvector('simple', coalesce("originalContent", '')), 'C')
WHERE "searchVector" IS NULL;
