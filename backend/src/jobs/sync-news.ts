import { prisma } from '../lib/prisma'
import { fetchLatestNews } from '../services/news-fetcher'
import { summarizeArticle } from '../services/summarizer'
import { scrapeArticleText } from '../services/scraper'

export async function syncNewsJob() {
  console.log('🔄 Starting news sync job...')
  
  const languages: ('en' | 'id')[] = ['en', 'id']
  
  for (const lang of languages) {
    console.log(`Fetching ${lang} news...`)
    let rawArticles = await fetchLatestNews(lang)
    
    // Batasi 15 berita agar ada cukup cadangan setelah difilter
    rawArticles = rawArticles.slice(0, 15)
    
    let addedCount = 0;
    
    for (const raw of rawArticles) {
      // 1. Filter out Ads / Promos
      const adKeywords = [
        'promo', 'diskon', 'voucher', 'cashback', 'belanja', 'jual', 'beli', 
        'deals', 'sale', 'sponsored', 'iklan', 'marketing', 'affiliate'
      ];
      const isAd = adKeywords.some(kw => 
        raw.title.toLowerCase().includes(kw) || 
        (raw.description && raw.description.toLowerCase().includes(kw))
      );
      
      if (isAd) {
        console.log(`Skipping potential ad: ${raw.title}`);
        continue;
      }

      // 2. Check if exists
      const exists = await prisma.article.findUnique({
        where: { externalId: raw.article_id }
      })
      
      if (exists) {
        // console.log(`Skipping article ${raw.article_id} - already exists.`);
        continue;
      }
      
      // 2. Prepare content - Attempt to scrape full text first
      console.log(`Scraping content for: ${raw.title}...`);
      let fullContent = await scrapeArticleText(raw.link);
      
      // If scraping fails or returns very little, fallback to API content/description
      if (fullContent.length < 200) {
        fullContent = raw.content || raw.description || raw.title || "No content available";
      }
      
      // 3. Final Check: Filter out NewsData's "PAID PLAN" message
      if (fullContent.includes("ONLY AVAILABLE IN PAID PLANS")) {
        console.log(`Skipping article ${raw.article_id} - API content is paywalled.`);
        continue;
      }
      
      if (fullContent.length < 5) {
        console.log(`Skipping article ${raw.article_id} - truly empty.`);
        continue;
      }
      
      // 4. Summarize via AI (Placeholder for now)
      const summary = fullContent.substring(0, 250).trim() + '...'; 
      
      // 5. Save to DB
      try {
        await prisma.article.create({
          data: {
            externalId: raw.article_id,
            title: raw.title,
            originalContent: fullContent, // Now contains the scraped full text!
            summary: summary,
            sourceUrl: raw.link,
            sourceName: raw.source_id,
            imageUrl: raw.image_url,
            category: raw.category?.[0] || 'general',
            language: lang,
            publishedAt: raw.pubDate ? new Date(raw.pubDate) : new Date(),
          }
        })
        addedCount++;
      } catch (e) {
        console.error(`Failed to save article ${raw.article_id}:`, e)
      }
    }
    
    console.log(`✅ Synced ${addedCount} new ${lang} articles.`)
  }
}
