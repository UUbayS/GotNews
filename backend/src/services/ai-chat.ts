import Groq from 'groq-sdk'

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || 'dummy'
})

export async function askAIAboutArticle(articleContent: string, question: string): Promise<string> {
  try {
    const completion = await groq.chat.completions.create({
      messages: [
        {
          role: 'system',
          content: 'You are a helpful news assistant. Answer the user\'s question based ONLY on the provided article context. Keep it concise, factual, and use the same language as the question (Indonesian or English).'
        },
        {
          role: 'user',
          content: `Context Article:\n${articleContent}\n\nQuestion: ${question}`
        }
      ],
      model: 'llama-3.3-70b-versatile',
      temperature: 0.5,
      max_tokens: 300,
    })

    return completion.choices[0]?.message?.content || "Sorry, I couldn't generate an answer."
  } catch (e) {
    console.error('Groq AI Chat error:', e)
    return "Error communicating with AI service."
  }
}
