import Groq from 'groq-sdk'

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || 'dummy'
})

export async function summarizeArticle(content: string, language: string = 'en'): Promise<string> {
  const provider = process.env.AI_PROVIDER || 'groq';

  const systemPrompt = `Summarize this news article into exactly 3 short, punchy sentences suitable for a young audience. The output must be in ${language === 'id' ? 'Indonesian' : 'English'}. Return ONLY the summary, no other text.`;

  if (provider === 'groq' && process.env.GROQ_API_KEY) {
    try {
      const completion = await groq.chat.completions.create({
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: content }
        ],
        model: 'llama3-8b-8192',
        temperature: 0.5,
        max_tokens: 150,
      });
      return completion.choices[0]?.message?.content?.trim() || '';
    } catch (e) {
      console.error('Groq summarization error:', e);
      return '';
    }
  } else if (provider === 'ollama') {
    // Fallback to local ollama
    try {
      const response = await fetch('http://localhost:11434/api/generate', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: 'llama3',
          prompt: `${systemPrompt}\n\nArticle: ${content}`,
          stream: false
        })
      });
      const data = await response.json();
      return data.response?.trim() || '';
    } catch (e) {
      console.error('Ollama summarization error:', e);
      return '';
    }
  }

  return '';
}
