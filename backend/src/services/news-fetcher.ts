export interface RawArticle {
  article_id: string;
  title: string;
  link: string;
  description?: string;
  content?: string;
  pubDate: string;
  image_url?: string;
  source_id: string;
  category?: string[];
  language: string;
}

export async function fetchLatestNews(language: 'en' | 'id' = 'en'): Promise<RawArticle[]> {
  const apiKey = process.env.NEWSDATA_API_KEY;
  if (!apiKey) {
    console.warn('No NEWSDATA_API_KEY found, skipping fetch.');
    return [];
  }

  try {
    const url = `https://newsdata.io/api/1/latest?apikey=${apiKey}&language=${language}`;
    console.log(`Fetching from NewsData.io (${language}): ${url}`);
    
    const response = await fetch(url);
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`NewsData API error (${response.status}): ${errorText}`);
      return [];
    }
    
    const data: any = await response.json();
    if (data.status === 'error') {
      console.error(`NewsData API error: ${data.message || JSON.stringify(data.results)}`);
      return [];
    }

    console.log(`Fetched ${data.results?.length || 0} articles from NewsData.`);
    return data.results || [];
  } catch (error) {
    console.error('Failed to fetch news:', error);
    return [];
  }
}
