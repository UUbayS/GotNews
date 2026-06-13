-- Drop old trigger if exists
DROP TRIGGER IF EXISTS trg_article_search_vector ON "Article";
DROP FUNCTION IF EXISTS article_search_vector_trigger();

-- Re-create trigger function using camelCase "searchVector"
CREATE OR REPLACE FUNCTION article_search_vector_trigger() RETURNS trigger AS $$
BEGIN
  NEW."searchVector" := 
    setweight(to_tsvector('simple', coalesce(NEW.title, '')), 'A') ||
    setweight(to_tsvector('simple', coalesce(NEW.summary, '')), 'B') ||
    setweight(to_tsvector('simple', coalesce(NEW."originalContent", '')), 'C');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Re-create trigger
CREATE TRIGGER trg_article_search_vector
  BEFORE INSERT OR UPDATE ON "Article"
  FOR EACH ROW EXECUTE FUNCTION article_search_vector_trigger();

-- Re-create dropped GIN indexes
CREATE INDEX IF NOT EXISTS idx_article_search ON "Article" USING GIN("searchVector");
CREATE INDEX IF NOT EXISTS idx_article_title_trgm ON "Article" USING GIN(title gin_trgm_ops);
