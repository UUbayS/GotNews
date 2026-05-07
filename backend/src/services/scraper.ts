import { parseHTML } from 'linkedom';

/**
 * Smartly extracts main article text from a given URL.
 * It fetches the HTML and tries to find the core content by looking at 
 * <article> tags or high concentrations of <p> tags.
 */
export async function scrapeArticleText(url: string): Promise<string> {
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      }
    });

    if (!response.ok) return '';
    
    const html = await response.text();
    const { document } = parseHTML(html);

    // Remove unwanted elements
    const unwanted = ['script', 'style', 'nav', 'footer', 'header', 'aside', 'iframe', 'ads'];
    unwanted.forEach(tag => {
      document.querySelectorAll(tag).forEach(el => el.remove());
    });

    // 1. Try common article containers (added ID specific ones)
    let contentElement = document.querySelector('article') || 
                         document.querySelector('main') || 
                         document.querySelector('[role="main"]') ||
                         document.querySelector('.detail__body-text') || // Detik
                         document.querySelector('.read__content') ||      // Kompas
                         document.querySelector('.article-content') ||
                         document.querySelector('.post-content') ||
                         document.querySelector('.article-body');

    // 2. If no common container, find the element with the most <p> tags
    if (!contentElement) {
      const allDivs = Array.from(document.querySelectorAll('div'));
      let maxP = 0;
      allDivs.forEach(div => {
        const pCount = div.querySelectorAll('p').length;
        if (pCount > maxP) {
          maxP = pCount;
          contentElement = div;
        }
      });
    }

    // 3. Fallback to body if still nothing
    const finalElement = contentElement || document.body;

    // 4. Extract and clean text from all <p> tags inside the container
    const paragraphs = Array.from(finalElement.querySelectorAll('p'))
      .map(p => p.textContent?.trim())
      .filter(text => text && text.length > 20); // Filter out very short lines (like captions)

    if (paragraphs.length === 0) {
      // Last resort: just get all text from the element
      return finalElement.textContent?.trim().replace(/\s+/g, ' ').substring(0, 5000) || '';
    }

    return paragraphs.join('\n\n').substring(0, 8000); // Limit to 8k chars for AI context
  } catch (error) {
    console.error(`Scraping failed for ${url}:`, error);
    return '';
  }
}
