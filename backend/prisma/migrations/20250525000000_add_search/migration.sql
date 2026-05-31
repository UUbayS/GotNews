CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE "Article" ADD COLUMN IF NOT EXISTS search_vector tsvector;

UPDATE "Article" SET search_vector = 
  setweight(to_tsvector('simple', coalesce(title, '')), 'A') ||
  setweight(to_tsvector('simple', coalesce(summary, '')), 'B') ||
  setweight(to_tsvector('simple', coalesce("originalContent", '')), 'C');

CREATE OR REPLACE FUNCTION article_search_vector_trigger() RETURNS trigger AS $$
BEGIN
  NEW.search_vector := 
    setweight(to_tsvector('simple', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(NEW.summary, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(NEW."originalContent", '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_article_search_vector 
  BEFORE INSERT OR UPDATE ON "Article"
  FOR EACH ROW EXECUTE FUNCTION article_search_vector_trigger();

CREATE INDEX IF NOT EXISTS idx_article_search ON "Article" USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_article_title_trgm ON "Article" USING GIN(title gin_trgm_ops);
